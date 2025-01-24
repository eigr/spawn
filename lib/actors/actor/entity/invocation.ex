defmodule Actors.Actor.Entity.Invocation do
  @moduledoc """
  Handles Invocation functions for Actor Entity
  All the public functions here assumes they are executing inside a GenServer
  """
  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Actors.Actor.Entity.EntityState
  alias Actors.Actor.Entity.Lifecycle
  alias Actors.Actor.Entity.Lifecycle.StreamInitiator
  alias Actors.Actor.InvocationScheduler
  alias Actors.Exceptions.NotAuthorizedException
  alias Actors.Actor.Pubsub
  alias Actors.Actor.StateManager

  alias Spawn.Actors.{
    Actor,
    ActorId,
    ActorSettings,
    ActorSystem,
    ActorState,
    Action,
    FixedTimerAction
  }

  alias Spawn.{
    ActorInvocation,
    ActorInvocationResponse,
    Broadcast,
    Context,
    Fact,
    Forward,
    InvocationRequest,
    Pipe,
    SideEffect,
    Workflow,
    Noop
  }

  alias Spawn.Utils.Nats

  import Spawn.Utils.AnySerializer,
    only: [any_pack!: 1, any_unpack!: 2, normalize_package_name: 1]

  import Spawn.Utils.Common, only: [return_and_maybe_hibernate: 1]

  @default_actions [
    "get",
    "Get",
    "get_state",
    "getState",
    "GetState"
  ]

  @default_init_actions [
    "init",
    "Init",
    "setup",
    "Setup"
  ]

  @http_host_interface Actors.Actor.Interface.Http

  def process_projection_events(messages, state) do
    %EntityState{actor: %Actor{} = actor} = state

    invocations =
      messages
      |> Enum.map(fn %Broadway.Message{data: %Fact{} = message} ->
        system_name = Map.get(message.metadata, "spawn-system")
        parent = Map.get(message.metadata, "actor-parent")
        name = Map.get(message.metadata, "actor-name")
        source_action = Map.get(message.metadata, "actor-action")

        action =
          actor.settings.projection_settings.subjects
          |> Enum.find(fn subject -> subject.source_action == source_action end)
          |> Map.get(:action)

        %InvocationRequest{
          async: true,
          system: %ActorSystem{name: system_name},
          actor: %Actor{id: actor.id},
          metadata: message.metadata,
          action_name: action,
          payload: {:value, Google.Protobuf.Any.decode(message.state)},
          caller: %ActorId{name: name, system: system_name, parent: parent}
        }
      end)

    spawn(fn ->
      invocations
      |> Flow.from_enumerable(min_demand: 1, max_demand: System.schedulers_online())
      |> Flow.map(fn invocation ->
        try do
          Actors.invoke(invocation, span_ctx: Tracer.current_span_ctx())
        catch
          error ->
            Logger.warning(
              "Error during processing events on projection. Invocation: #{inspect(invocation)} Error: #{inspect(error)}"
            )

            :ok
        end
      end)
      |> Flow.run()
    end)

    {:noreply, state}
  end

  def replay(
        call_opts,
        %EntityState{
          actor:
            %Actor{
              settings:
                %ActorSettings{
                  kind: :PROJECTION
                } = _settings
            } = actor,
          projection_stream_pid: stream_pid
        } = state
      ) do
    {:ok, newpid} = StreamInitiator.replay(stream_pid, actor, call_opts)
    {:noreply, %{state | projection_stream_pid: newpid}}
  end

  def replay(_replaymsg, _call_opts, state), do: {:noreply, state}

  def handle_timers([], _system, _actor), do: :ok

  def handle_timers(timers, system, actor) when is_list(timers) do
    invocations =
      Enum.map(timers, fn %FixedTimerAction{action: %Action{name: action}, seconds: delay} ->
        invocation_request = %InvocationRequest{
          actor: actor,
          action_name: action,
          payload: {:noop, %Noop{}},
          async: true,
          scheduled_to: 0,
          caller: actor.id,
          system: %ActorSystem{name: system}
        }

        scheduled_to =
          DateTime.utc_now()
          |> DateTime.add(delay, :millisecond)

        {invocation_request, scheduled_to, delay}
      end)

    InvocationScheduler.schedule_fixed_invocations(invocations)

    :ok
  catch
    error -> Logger.error("Error on handle timers #{inspect(error)}")
  end

  def handle_timers(nil, _system, _actor), do: :ok

  @doc """
  Handles the initialization invocation for an Actor Entity.

  ## Parameters

  - `state` (%EntityState{}): The current state of the Actor Entity.

  ## Returns

  - `{:noreply, new_state}`: If the initialization is successful.
  - `{:noreply, new_state}`: If the actor has not registered any actions, indicating a warning.
  - `{:error, reason, new_state}`: If there is an error during the initialization, returns a tuple with the reason for the error and the updated entity state.

  ## Behavior

  The `invoke_init/1` function is responsible for handling the initialization invocation of an Actor Entity. It checks if the actor has registered any actions and performs the following steps:

  1. **Action Registration Check:** Checks if the actor has registered any actions. If not, it logs a warning and returns `{:noreply, new_state}`.

  2. **Init Action Selection:** Filters the registered actions to find the initialization action (`init` or similar) and selects the first matching action.

  3. **Interface Invocation:** Invokes the selected initialization action using the appropriate interface.

  4. **Handling Initialization Result:** Processes the result of the initialization, updating the entity state accordingly.

  ## Example

  ```elixir
  state = %EntityState{
    system: %ActorSystem{name: "example_system"},
    actor: %Actor{
      id: %ActorId{name: "example_actor"},
      actions: ["init", "perform_action"],
      state: %{}
    },
    opts: %{}
  }

  case Actors.Actor.Entity.Invocation.invoke_init(state) do
    {:noreply, new_state} ->
      IO.puts("Initialization successful!")
    {:error, reason, new_state} ->
      IO.puts("Initialization failed. Reason: {reason}")
  end
  ```

  """
  def invoke_init(
        %EntityState{
          system: actor_system,
          actor:
            %Actor{
              id: %ActorId{name: actor_name, parent: parent} = id,
              state: actor_state,
              actions: actions
            } = _actor,
          opts: actor_opts
        } = state
      ) do
    if length(actions) <= 0 do
      Logger.warning("Actor [#{actor_name}] has not registered any Actions")

      {:noreply, state}
      |> return_and_maybe_hibernate()
    else
      init_action =
        Enum.filter(actions, fn cmd -> Enum.member?(@default_init_actions, cmd.name) end)
        |> Enum.at(0)

      case init_action do
        nil ->
          {:noreply, state}
          |> return_and_maybe_hibernate()

        _ ->
          interface = get_interface(actor_opts)

          metadata = %{}
          current_state = Map.get(actor_state || %{}, :state) || %ActorState{}
          current_tags = Map.get(actor_state || %{}, :tags, %{})

          %ActorInvocation{
            actor: %ActorId{name: actor_name, system: actor_system, parent: parent},
            action_name: init_action.name,
            payload: {:noop, %Noop{}},
            current_context: %Context{
              metadata: metadata,
              caller: id,
              self: %ActorId{name: actor_name, system: actor_system},
              state: current_state,
              tags: current_tags
            },
            caller: id
          }
          |> interface.invoke_host(state, @default_actions)
          |> case do
            {:ok, _response, new_state} ->
              {:noreply, new_state}

            {:error, _reason, new_state} ->
              {:noreply, new_state}
              |> return_and_maybe_hibernate()
          end
      end
    end
  end

  @doc """
  Handles the invocation of actions on an Actor Entity.

  ## Parameters

  - `invocation` (%InvocationRequest{}): A struct representing the invocation request, including details about the actor, action, and payload.
  - `opts` (Keyword.t): Additional options for the invocation.

  ## Returns

  - `{:reply, result, new_state}`: If the invocation is successful, returns a tuple containing the reply result, and the updated entity state.
  - `{:noreply, new_state}`: If the invocation is successful, but there is no specific reply result.
  - `{:noreply, new_state, opts}`: If the invocation is successful and includes additional options.
  - `{:error, reason, new_state}`: If there is an error during the invocation, returns a tuple with the reason for the error and the updated entity state.

  ## Behavior

  The `invoke/2` function is responsible for handling the invocation of actions on an Actor Entity.
  It verifies authorization, finds the appropriate action to execute, and delegates the invocation to the corresponding interface.

  The function performs the following steps:

  1. **Authorization Check:** Checks if the invocation is authorized based on the actor's actions and timers.

  2. **Span Context Handling:** Uses OpenTelemetry for tracing and creates a new span for the invocation.

  3. **Find Request by Action:** Determines the appropriate interface and builds the request based on the action.

  4. **Invocation Host Handling:** Delegates the invocation to the selected interface's `invoke_host/3` function.

  5. **Handle Response:** Processes the response from the invocation, handles side effects, and updates the entity state.

  6. **Checkpoint:** Optionally performs a checkpoint operation to record the state revision.

  ## Example

  ```elixir
  invocation = %InvocationRequest{
    actor: %Actor{id: %ActorId{name: "example_actor"}},
    action_name: "perform_action",
    payload: {:data, %{}},
    caller: %ActorId{name: "caller_actor"}
  }

  opts = [span_ctx: OpenTelemetry.Ctx.new()]

  case Actors.Actor.Entity.Invocation.invoke({invocation, opts}, entity_state) do
    {:reply, result, new_state} ->
      IO.puts("Invocation successful! Result: {result}")
    {:noreply, new_state} ->
      IO.puts("Invocation successful! No specific reply.")
    {:error, reason, new_state} ->
      IO.puts("Invocation failed. Reason: {reason}")
  end
  ```

  """
  def invoke(
        {%InvocationRequest{
           actor: %Actor{id: %ActorId{name: actor_name} = _id} = _actor,
           action_name: action_name
         } = invocation, opts},
        %EntityState{
          actor: %Actor{state: actor_state, actions: actions, timer_actions: timers},
          opts: actor_opts
        } = state
      ) do
    if is_authorized?(invocation, actions, timers) do
      all_opts = Keyword.merge(actor_opts, opts)
      ctx = Keyword.get(opts, :span_ctx, OpenTelemetry.Ctx.new())

      Tracer.with_span ctx, "#{actor_name} invocation handler", kind: :server do
        case find_request_by_action(
               invocation,
               actor_state,
               action_name,
               actions,
               timers,
               all_opts
             ) do
          {:ok, {interface, request, action_type}} ->
            if action_type == :view_action do
              handle_view_invocation(request, state, all_opts)
            else
              handle_invocation(interface, request, state, all_opts)
            end

          {:error, :not_found} ->
            handle_not_found_action(action_name, actor_name, state)
        end
      end
    else
      raise NotAuthorizedException
    end
  end

  def handle_response(
        request,
        %ActorInvocationResponse{checkpoint: checkpoint} = response,
        %EntityState{
          actor:
            %Actor{
              id: id,
              settings:
                %ActorSettings{
                  kind: kind,
                  projection_settings: projection_settings
                } = _settings
            } = _actor,
          revision: revision
        } = state,
        opts
      ) do
    response_params = %{
      actor_id: id,
      kind: kind,
      projection_settings: projection_settings,
      request: request,
      response: response,
      state: state,
      opts: opts
    }

    response =
      case do_response(response_params) do
        :noreply ->
          {:noreply, state}
          |> return_and_maybe_hibernate()

        response ->
          {:reply, {:ok, response}, state}
          |> return_and_maybe_hibernate()
      end

    response_checkpoint(response, checkpoint, revision, state)
  end

  defp is_authorized?(invocation, _actions, _timers) do
    acl_manager = get_acl_manager()

    acl_manager.get_policies!()
    # and length(actions ++ timers) > 0
    |> acl_manager.is_authorized?(invocation)
  end

  defp find_request_by_action(invocation, actor_state, action, actions, timers, actor_opts) do
    all_actions = actions ++ Enum.map(timers, & &1.action)

    case get_action_type(invocation, action, all_actions) do
      :not_found ->
        {:error, :not_found}

      action_type ->
        interface = get_interface(actor_opts)
        request = build_request(invocation, actor_state, actor_opts)

        {:ok, {interface, request, action_type}}
    end
  end

  defp get_action_type(invocation, action, actions) do
    cond do
      Enum.member?(@default_actions, action) ->
        :default_action

      Enum.any?(actions, &(&1.name == action)) ->
        :registered_action

      !!:persistent_term.get("view-#{invocation.actor.id.name}-#{action}", false) ->
        :view_action

      true ->
        :not_found
    end
  end

  defp handle_invocation(interface, request, state, opts) do
    Tracer.with_span "invoke-host" do
      case interface.invoke_host(request, state, @default_actions) do
        {:ok, response, new_state} ->
          {:ok, request, response, new_state, opts}

        {:error, reason, new_state} ->
          {:reply, {:error, reason}, new_state}
          |> return_and_maybe_hibernate()
      end
    end
  end

  defp handle_view_invocation(request, state, opts) do
    Tracer.with_span "invoke-host" do
      view = :persistent_term.get("view-#{request.actor.name}-#{request.action_name}")

      page_size =
        if Map.get(view, :page_size, 0) == 0 do
          10
        else
          Map.get(view, :page_size)
        end

      page =
        "#{Map.get(request.current_context.metadata || %{}, "page", 1)}" |> String.to_integer()

      page_size =
        "#{Map.get(request.current_context.metadata || %{}, "page_size", page_size)}"
        |> String.to_integer()

      {type, payload} = request.payload

      payload =
        if type == :noop do
          payload
        else
          any_unpack!(payload, view.input_type)
        end

      {:ok, results} =
        StateManager.projection_query(view.query_result_type, view.query, payload,
          page_size: page_size,
          page: page
        )

      response = Map.put(view.output_type.__struct__(), String.to_atom(view.map_to), results)

      %ActorInvocation{
        actor: %ActorId{name: name, system: system},
        caller: caller
      } = request

      current_state = Map.get(state.actor.state || %{}, :state, %Google.Protobuf.Any{})
      current_tags = Map.get(state.actor.state || %{}, :tags, %{})

      context =
        %Context{
          caller: caller,
          self: state.actor.id,
          state: current_state,
          tags: current_tags
        }

      response = %ActorInvocationResponse{
        actor_name: name,
        actor_system: system,
        updated_context: context,
        payload: {:value, any_pack!(response)}
      }

      {:ok, request, response, state, opts}
    end
  end

  defp handle_not_found_action(action, actor_name, state) do
    Logger.warning("Action [#{action}] not found for Actor [#{actor_name}]")

    {:reply,
     {:error, :action_not_found, "Action [#{action}] not found for Actor [#{actor_name}]"}, state,
     :hibernate}
  end

  defp build_request(
         %InvocationRequest{
           actor:
             %Actor{
               id: %ActorId{} = id
             } = _actor,
           metadata: metadata,
           action_name: action,
           payload: payload,
           caller: caller
         },
         actor_state,
         _opts
       ) do
    metadata = if is_nil(metadata), do: %{}, else: metadata
    current_state = Map.get(actor_state || %{}, :state)
    current_tags = Map.get(actor_state || %{}, :tags, %{})

    # TODO: Validate state before invoke

    %ActorInvocation{
      actor: id,
      action_name: action,
      payload: payload,
      current_context: %Context{
        caller: caller,
        self: id,
        state: current_state,
        metadata: metadata,
        tags: current_tags
      },
      caller: caller
    }
  end

  defp response_checkpoint(response, checkpoint, revision, state) do
    if checkpoint do
      Lifecycle.checkpoint(revision, state)
    else
      response
    end
  end

  defp do_response(
         %{
           actor_id: id,
           projection_settings: settings,
           request: request,
           response: %ActorInvocationResponse{workflow: workflow} = response,
           state: state,
           opts: _opts
         } = _params
       )
       when is_nil(workflow) or workflow == %{} do
    :ok = do_handle_projection(id, request.action_name, settings, state, response)

    response
  end

  defp do_response(
         %{
           actor_id: id,
           projection_settings: settings,
           request: request,
           response: response,
           state: state,
           opts: opts
         } = _params
       ) do
    :ok = do_handle_projection(id, request.action_name, settings, state, response)

    do_run_workflow(request, response, state, opts)
  end

  defp do_handle_projection(id, action, %{sourceable: true} = _settings, _state, response) do
    stream_name = StreamInitiator.stream_name(id)
    id_name = String.replace(id.name, ".", "-")

    subject = "actors.#{stream_name}.#{id_name}.#{action}"
    payload = Google.Protobuf.Any.encode(response.updated_context.state)

    uuid = UUID.uuid4(:hex)

    Gnat.pub(Nats.connection_name(), subject, payload,
      headers: [
        {"Nats-Msg-Id", uuid},
        {"Spawn-System", "#{id.system}"},
        {"Actor-Parent", "#{id.parent}"},
        {"Actor-Name", "#{id.name}"},
        {"Actor-Action", "#{action}"}
      ]
    )
  end

  defp do_handle_projection(
         id,
         action,
         _settings,
         %EntityState{actor: %Actor{settings: %ActorSettings{kind: :PROJECTION}}} = state,
         response
       ) do
    if :persistent_term.get("view-#{id.name}-#{action}", false) do
      # no need to persist any state since this is a view only action
      :ok
    else
      state_type =
        state.actor.settings.state_type
        |> normalize_package_name()

      table_name =
        if is_nil(id.parent) or id.parent == "" do
          Macro.underscore(id.name)
        else
          Macro.underscore(id.parent)
        end

      StateManager.projection_upsert(
        state_type,
        table_name,
        any_unpack!(response.updated_context.state, state_type)
      )
    end
  end

  defp do_handle_projection(_id, _action, _settings, _state, _response), do: :ok

  defp do_run_workflow(
         _request,
         %ActorInvocationResponse{workflow: workflow} = response,
         _state,
         _opts
       )
       when is_nil(workflow) or workflow == %{} do
    response
  end

  defp do_run_workflow(
         request,
         %ActorInvocationResponse{
           workflow: %Workflow{broadcast: broadcast, effects: effects} = _workflow
         } = response,
         _state,
         opts
       ) do
    Tracer.with_span "run-workflow" do
      do_side_effects(request, effects, opts)
      do_broadcast(request, broadcast, opts)
      do_handle_routing(request, response, opts)
    end
  end

  defp do_handle_routing(
         _request,
         %ActorInvocationResponse{
           workflow: %Workflow{routing: routing} = _workflow
         } = response,
         _opts
       )
       when is_nil(routing),
       do: response

  defp do_handle_routing(
         %ActorInvocation{
           actor: %ActorId{name: caller_actor_name, system: system_name},
           current_context: %Context{metadata: metadata}
         },
         %ActorInvocationResponse{
           payload: payload,
           workflow:
             %Workflow{
               routing: {:pipe, %Pipe{actor: actor_name, action_name: cmd} = _pipe} = _workflow
             } = response
         },
         opts
       ) do
    from_pid = Keyword.get(opts, :from_pid)

    dispatch_routing_to_caller(from_pid, fn ->
      Tracer.with_span "run-pipe-routing" do
        invocation = %InvocationRequest{
          system: %ActorSystem{name: system_name},
          actor: %Actor{id: %ActorId{name: actor_name, system: system_name}},
          action_name: cmd,
          metadata: metadata,
          payload: payload,
          caller: %ActorId{name: caller_actor_name, system: system_name}
        }

        try do
          case Actors.invoke(invocation,
                 span_ctx: OpenTelemetry.Tracer.current_span_ctx()
               ) do
            {:ok, response} ->
              {:ok, response}

            error ->
              error
          end
        catch
          error ->
            Logger.warning(
              "Error during Pipe request to Actor #{system_name}:#{actor_name}. Error: #{inspect(error)}"
            )

            {:ok, response}
        end
      end
    end)
  end

  defp do_handle_routing(
         %ActorInvocation{
           actor: %ActorId{name: caller_actor_name, system: system_name},
           payload: payload,
           current_context: %Context{metadata: metadata}
         } = _request,
         %ActorInvocationResponse{
           workflow:
             %Workflow{
               routing:
                 {:forward, %Forward{actor: actor_name, action_name: cmd} = _pipe} = _workflow
             } = response
         },
         opts
       ) do
    from_pid = Keyword.get(opts, :from_pid)

    dispatch_routing_to_caller(from_pid, fn ->
      Tracer.with_span "run-forward-routing" do
        invocation = %InvocationRequest{
          system: %ActorSystem{name: system_name},
          actor: %Actor{id: %ActorId{name: actor_name, system: system_name}},
          action_name: cmd,
          metadata: metadata,
          payload: payload,
          caller: %ActorId{name: caller_actor_name, system: system_name}
        }

        try do
          case Actors.invoke(invocation,
                 span_ctx: OpenTelemetry.Tracer.current_span_ctx()
               ) do
            {:ok, response} ->
              {:ok, response}

            error ->
              error
          end
        catch
          error ->
            Logger.warning(
              "Error during Forward request to Actor #{system_name}:#{actor_name}. Error: #{inspect(error)}"
            )

            {:ok, response}
        end
      end
    end)
  end

  def do_broadcast(_request, broadcast, _opts \\ [])

  def do_broadcast(_request, broadcast, _opts)
      when is_nil(broadcast) or broadcast == %{} do
    :ok
  end

  def do_broadcast(
        request,
        %Broadcast{channel_group: channel, payload: payload} = _broadcast,
        _opts
      ) do
    Tracer.with_span "run-broadcast" do
      Tracer.add_event("publish", [{"channel", channel}])

      Pubsub.publish(channel, payload, request)
    end
  end

  defp dispatch_routing_to_caller(from, callback)
       when is_function(callback) and is_nil(from),
       do: callback.()

  defp dispatch_routing_to_caller(from, callback) when is_function(callback) do
    spawn(fn -> GenServer.reply(from, callback.()) end)
    :noreply
  end

  def do_side_effects(request, effects, opts \\ [])

  def do_side_effects(_request, effects, _opts) when effects == [] do
    :ok
  end

  def do_side_effects(request, effects, _opts) when is_list(effects) do
    Tracer.with_span "handle-side-effects" do
      try do
        spawn(fn ->
          effects
          |> Flow.from_enumerable(min_demand: 1, max_demand: System.schedulers_online())
          |> Flow.map(fn %SideEffect{
                           request:
                             %InvocationRequest{
                               actor: %Actor{id: %ActorId{name: actor_name} = _id} = _actor,
                               system: %ActorSystem{name: system_name}
                             } = invocation
                         } ->
            try do
              metadata = Map.merge(request.current_context.metadata, invocation.metadata)
              invocation = %InvocationRequest{invocation | metadata: metadata}

              Actors.invoke(invocation, span_ctx: Tracer.current_span_ctx())
            catch
              error ->
                Logger.warning(
                  "Error during Side Effect request to Actor #{system_name}:#{actor_name}. Error: #{inspect(error)}"
                )

                :ok
            end
          end)
          |> Flow.run()
        end)
      catch
        error ->
          Logger.warning("Error during Side Effect request. Error: #{inspect(error)}")
          :ok
      end
    end
  end

  defp get_interface(opts), do: Keyword.get(opts, :interface, @http_host_interface)

  defp get_acl_manager(),
    do: Application.get_env(:spawn, :acl_manager, Actors.Security.Acl.DefaultAclManager)
end
