defmodule Actors.Actor.Entity.Invocation do
  @moduledoc """
  Handles Invocation functions for Actor Entity
  All the public functions here assumes they are executing inside a GenServer
  """
  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Actors.Actor.Entity.EntityState
  alias Actors.Exceptions.NotAuthorizedException
  alias Actors.Security.Acl.DefaultAclManager

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorSystem,
    ActorState,
    Action,
    FixedTimerAction
  }

  alias Eigr.Functions.Protocol.{
    ActorInvocation,
    ActorInvocationResponse,
    Broadcast,
    Context,
    Forward,
    InvocationRequest,
    Pipe,
    SideEffect,
    Workflow,
    Noop
  }

  alias Phoenix.PubSub

  alias Spawn.Utils.AnySerializer

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

  def timer_invoke(
        %FixedTimerAction{action: %Action{name: cmd} = _action} = timer,
        %EntityState{
          system: _actor_system,
          actor: %Actor{id: caller_actor_id} = actor
        } = state
      ) do
    invocation = %InvocationRequest{
      actor: actor,
      action_name: cmd,
      payload: {:noop, %Noop{}},
      async: true,
      caller: caller_actor_id
    }

    invoke_result = invoke({invocation, []}, state)

    :ok = handle_timers([timer])

    case invoke_result do
      {:reply, _res, state} -> {:noreply, state}
      {:reply, _res, state, opts} -> {:noreply, state, opts}
    end
  end

  def handle_timers(timers) when is_list(timers) do
    if length(timers) > 0 do
      timers
      |> Stream.map(fn %FixedTimerAction{seconds: delay} = timer_action ->
        Process.send_after(self(), {:invoke_timer_action, timer_action}, delay)
      end)
      |> Stream.run()
    end

    :ok
  catch
    error -> Logger.error("Error on handle timers #{inspect(error)}")
  end

  def handle_timers(nil), do: :ok

  def handle_timers([]), do: :ok

  def broadcast_invoke(
        action,
        payload,
        %ActorInvocation{actor: %ActorId{name: caller_actor_name, system: actor_system}},
        %EntityState{
          system: actor_system,
          actor: %Actor{id: %ActorId{name: actor_name} = _id} = actor
        } = state
      ) do
    Logger.debug(
      "Actor [#{actor_name}] Received Broadcast Event [#{inspect(payload)}] to perform Action [#{action}]"
    )

    invocation = %InvocationRequest{
      actor: actor,
      action_name: action,
      payload: payload,
      async: true,
      caller: %ActorId{name: caller_actor_name, system: actor_system}
    }

    case invoke({invocation, []}, state) do
      {:reply, _res, state} -> {:noreply, state}
      {:reply, _res, state, opts} -> {:noreply, state, opts}
    end
  end

  def broadcast_invoke(
        payload,
        %EntityState{
          system: _actor_system,
          actor: %Actor{id: %ActorId{name: actor_name} = _id} = _actor
        } = state
      ) do
    Logger.debug(
      "Actor [#{actor_name}] Received Broadcast Event [#{inspect(payload)}] without action. Just ignoring"
    )

    {:noreply, state}
  end

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
      {:noreply, state, :hibernate}
    else
      init_action =
        Enum.filter(actions, fn cmd -> Enum.member?(@default_init_actions, cmd.name) end)
        |> Enum.at(0)

      case init_action do
        nil ->
          {:noreply, state, :hibernate}

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
              {:noreply, new_state, :hibernate}
          end
      end
    end
  end

  @doc """
  Invoke function, receives a request and calls invoke host with the response
  """
  def invoke(
        {%InvocationRequest{
           actor:
             %Actor{
               id: %ActorId{name: actor_name} = _id
             } = _actor,
           action_name: action
         } = invocation, opts},
        %EntityState{
          system: _actor_system,
          actor: %Actor{state: actor_state, actions: actions, timer_actions: timers},
          opts: actor_opts
        } = state
      ) do
    if get_acl_manager().get_policies!()
       |> get_acl_manager().is_authorized?(invocation) do
      ctx = Keyword.get(opts, :span_ctx, OpenTelemetry.Ctx.new())

      Tracer.with_span ctx, "#{actor_name} invocation handler", kind: :server do
        if length(actions) <= 0 do
          Logger.warning("Actor [#{actor_name}] has not registered any Actions")
        end

        all_actions =
          actions ++
            Enum.map(timers, fn %FixedTimerAction{action: cmd} = _timer_cmd -> cmd end)

        Tracer.set_attributes([
          {:invoked_action, action},
          {:actor_declared_actions, length(all_actions)}
        ])

        case Enum.member?(@default_actions, action) or
               Enum.any?(all_actions, fn cmd -> cmd.name == action end) do
          true ->
            interface = get_interface(actor_opts)

            request = build_request(invocation, actor_state, opts)

            Tracer.with_span "invoke-host" do
              interface.invoke_host(request, state, @default_actions)
              |> case do
                {:ok, response, new_state} ->
                  Tracer.add_event("successful-invocation", [
                    {:ok, "#{inspect(response.updated_context.metadata)}"}
                  ])

                  build_response(request, response, new_state, opts)

                {:error, reason, new_state} ->
                  Tracer.add_event("failure-invocation", [
                    {:error, "#{inspect(reason)}"}
                  ])

                  {:reply, {:error, reason}, new_state, :hibernate}
              end
            end

          false ->
            {:reply, {:error, "Action [#{action}] not found for Actor [#{actor_name}]"}, state,
             :hibernate}
        end
      end
    else
      raise NotAuthorizedException
    end
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

  defp build_response(request, response, state, opts) do
    case do_response(request, response, state, opts) do
      :noreply ->
        {:noreply, state}

      response ->
        {:reply, {:ok, response}, state}
    end
  end

  defp do_response(
         _request,
         %ActorInvocationResponse{workflow: workflow} = response,
         _state,
         _opts
       )
       when is_nil(workflow) or workflow == %{} do
    response
  end

  defp do_response(request, response, state, opts) do
    do_run_workflow(request, response, state, opts)
  end

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
      do_side_effects(effects, opts)
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
           actor: %ActorId{name: caller_actor_name, system: system_name}
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
          payload: payload,
          caller: %ActorId{name: caller_actor_name, system: system_name}
        }

        try do
          case Actors.invoke(invocation, span_ctx: OpenTelemetry.Tracer.current_span_ctx()) do
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
           payload: payload
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
          payload: payload,
          caller: %ActorId{name: caller_actor_name, system: system_name}
        }

        try do
          case Actors.invoke(invocation, span_ctx: OpenTelemetry.Tracer.current_span_ctx()) do
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

  def do_broadcast(_request, broadcast, _opts) when is_nil(broadcast) or broadcast == %{} do
    :ok
  end

  def do_broadcast(
        request,
        %Broadcast{channel_group: channel, action_name: action, payload: payload} = _broadcast,
        _opts
      ) do
    Tracer.with_span "run-broadcast" do
      Tracer.add_event("publish", [{"channel", channel}])
      Tracer.set_attributes([{:action, action}])

      spawn(fn -> publish(channel, action, payload, request) end)
    end
  end

  defp dispatch_routing_to_caller(from, callback)
       when is_function(callback) and is_nil(from),
       do: callback.()

  defp dispatch_routing_to_caller(from, callback) when is_function(callback) do
    spawn(fn -> GenServer.reply(from, callback.()) end)
    :noreply
  end

  defp publish(channel, action, payload, _request) when is_nil(action) or action == "" do
    PubSub.broadcast(
      :actor_channel,
      channel,
      {:receive, parse_external_broadcast_message(payload)}
    )
  end

  defp publish(channel, action, payload, request) do
    PubSub.broadcast(
      :actor_channel,
      channel,
      {:receive, action, payload, request}
    )
  end

  defp parse_external_broadcast_message({:value, %Google.Protobuf.Any{} = any}) do
    AnySerializer.unpack_unknown(any)
  end

  defp parse_external_broadcast_message(_any), do: %{}

  def do_side_effects(effects, opts \\ [])

  def do_side_effects(effects, _opts) when effects == [] do
    :ok
  end

  def do_side_effects(effects, _opts) when is_list(effects) do
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
