defmodule Actors.Actor.Entity do
  use GenServer, restart: :transient
  require Logger

  alias Actors.Actor.{Entity.EntityState, StateManager}
  alias Actors.Registry.HostActor

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorDeactivationStrategy,
    ActorSettings,
    ActorState,
    ActorSnapshotStrategy,
    ActorSystem,
    Command,
    FixedTimerCommand,
    Metadata,
    TimeoutStrategy
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

  import Actors, only: [invoke: 2]
  import Actors.Registry.ActorRegistry, only: [lookup: 2]

  @default_deactivate_timeout 10_000

  @default_host_interface Actors.Actor.Interface.Http

  @default_methods [
    "get",
    "Get",
    "get_state",
    "getState",
    "GetState"
  ]

  @default_snapshot_timeout 2_000

  @fullsweep_after 10

  @min_snapshot_threshold 500

  @timeout_factor_range 200..9000

  @impl true
  @spec init(EntityState.t()) ::
          {:ok, EntityState.t(), {:continue, :load_state}}
  def init(initial_state) do
    state = EntityState.unpack(initial_state)

    do_init(state)
    |> parse_packed_response()
  end

  defp do_init(
         %EntityState{
           actor: %Actor{
             id: %ActorId{name: name} = _id,
             metadata: metadata,
             settings:
               %ActorSettings{persistent: false, deactivation_strategy: deactivation_strategy} =
                 _settings,
             timer_commands: timer_commands
           }
         } = state
       )
       when is_nil(deactivation_strategy) or deactivation_strategy == %{} do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence disabled."
    )

    :ok = handle_metadata(name, metadata)
    :ok = handle_timers(timer_commands)

    strategy = {:timeout, TimeoutStrategy.new!(timeout: @default_deactivate_timeout)}
    schedule_deactivate(strategy, get_timeout_factor(@timeout_factor_range))
    {:ok, state}
  end

  defp do_init(
         %EntityState{
           actor: %Actor{
             id: %ActorId{name: name} = _id,
             metadata: metadata,
             settings:
               %ActorSettings{
                 persistent: false,
                 deactivation_strategy:
                   %ActorDeactivationStrategy{strategy: deactivation_strategy} = _dstrategy
               } = _settings,
             timer_commands: timer_commands
           }
         } = state
       ) do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence disabled."
    )

    :ok = handle_metadata(name, metadata)
    :ok = handle_timers(timer_commands)

    schedule_deactivate(deactivation_strategy, get_timeout_factor(@timeout_factor_range))
    {:ok, state}
  end

  defp do_init(
         %EntityState{
           actor: %Actor{
             id: %ActorId{name: name} = _id,
             metadata: metadata,
             settings:
               %ActorSettings{
                 persistent: true,
                 snapshot_strategy: %ActorSnapshotStrategy{} = _snapshot_strategy,
                 deactivation_strategy: deactivation_strategy
               } = _settings,
             timer_commands: timer_commands
           }
         } = state
       )
       when is_nil(deactivation_strategy) or deactivation_strategy == %{} do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence enabled."
    )

    :ok = handle_metadata(name, metadata)
    :ok = handle_timers(timer_commands)

    strategy = {:timeout, TimeoutStrategy.new!(timeout: @default_deactivate_timeout)}
    schedule_deactivate(strategy, get_timeout_factor(@timeout_factor_range))

    # Write soon in the first time
    schedule_snapshot_advance(@min_snapshot_threshold + get_timeout_factor(@timeout_factor_range))
    {:ok, state, {:continue, :load_state}}
  end

  defp do_init(
         %EntityState{
           actor: %Actor{
             id: %ActorId{name: name} = _id,
             metadata: metadata,
             settings:
               %ActorSettings{
                 persistent: true,
                 snapshot_strategy: %ActorSnapshotStrategy{} = _snapshot_strategy,
                 deactivation_strategy: %ActorDeactivationStrategy{
                   strategy: deactivation_strategy
                 }
               } = _settings,
             timer_commands: timer_commands
           }
         } = state
       ) do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{inspect(name)} in Node #{inspect(Node.self())}. Persistence enabled."
    )

    :ok = handle_metadata(name, metadata)
    :ok = handle_timers(timer_commands)

    schedule_deactivate(deactivation_strategy, get_timeout_factor(@timeout_factor_range))

    # Write soon in the first time
    schedule_snapshot_advance(@min_snapshot_threshold + get_timeout_factor(@timeout_factor_range))
    {:ok, state, {:continue, :load_state}}
  end

  @impl true
  @spec handle_continue(:load_state, EntityState.t()) :: {:noreply, EntityState.t()}
  def handle_continue(action, state) do
    state = EntityState.unpack(state)

    do_handle_continue(action, state)
    |> parse_packed_response()
  end

  defp do_handle_continue(
         :load_state,
         %EntityState{
           actor: %Actor{id: %ActorId{name: name} = _id, state: actor_state} = actor
         } = state
       )
       when is_nil(actor_state) do
    Logger.debug("Initial state is empty... Getting state from state manager.")

    case StateManager.load(name) do
      {:ok, current_state} ->
        {:noreply, %EntityState{state | actor: %Actor{actor | state: current_state}}}

      {:not_found, %{}} ->
        Logger.debug("Not found initial Actor State on statestore for Actor #{name}.")
        {:noreply, state, :hibernate}
    end
  end

  defp do_handle_continue(
         :load_state,
         %EntityState{
           actor:
             %Actor{id: %ActorId{name: name} = _id, state: %ActorState{} = _actor_state} = actor
         } = state
       ) do
    Logger.debug(
      "Initial state is not empty... Trying to reconcile the state with state manager."
    )

    case StateManager.load(name) do
      {:ok, current_state} ->
        # TODO: Merge current with old ?
        {:noreply, %EntityState{state | actor: %Actor{actor | state: current_state}}}

      {:not_found, %{}} ->
        Logger.debug("Not found initial state on statestore for Actor #{name}.")
        {:noreply, state, :hibernate}

      error ->
        Logger.error("Error on load state for Actor #{name}. Error: #{inspect(error)}")
        {:noreply, state, :hibernate}
    end
  end

  @impl true
  def handle_call(action, from, state) do
    state = EntityState.unpack(state)

    do_handle_call(action, from, state)
    |> parse_packed_response()
  end

  defp do_handle_call(
         :get_state,
         _from,
         %EntityState{
           actor: %Actor{state: actor_state} = _actor
         } = state
       )
       when is_nil(actor_state),
       do: {:reply, {:error, :not_found}, state, :hibernate}

  defp do_handle_call(
         :get_state,
         _from,
         %EntityState{
           actor: %Actor{state: %ActorState{} = actor_state} = _actor
         } = state
       ),
       do: {:reply, {:ok, actor_state}, state, :hibernate}

  defp do_handle_call(
         {:invocation_request,
          %InvocationRequest{
            actor:
              %Actor{
                id: %ActorId{name: actor_name} = _id
              } = _actor,
            command_name: command,
            payload: payload,
            caller: caller
          } = _invocation, opts},
         _from,
         %EntityState{
           system: actor_system,
           actor: %Actor{state: actor_state, commands: commands, timer_commands: timers}
         } = state
       ) do
    if length(commands) <= 0 do
      Logger.warning("Actor [#{actor_name}] has not registered any Actions")
    end

    all_commands =
      commands ++ Enum.map(timers, fn %FixedTimerCommand{command: cmd} = _timer_cmd -> cmd end)

    case Enum.member?(@default_methods, command) or
           Enum.any?(all_commands, fn cmd -> cmd.name == command end) do
      true ->
        interface = get_interface(actor_system, actor_name, opts)
        current_state = Map.get(actor_state || %{}, :state)

        request =
          ActorInvocation.new(
            actor_name: actor_name,
            actor_system: actor_system,
            command_name: command,
            payload: payload,
            current_context:
              Context.new(
                caller: caller,
                self: ActorId.new(name: actor_name, system: actor_system),
                state: current_state
              ),
            caller: caller
          )

        interface.invoke_host(request, state, @default_methods)
        |> case do
          {:ok, response, state} -> {:reply, {:ok, do_response(request, response, state)}, state}
          {:error, reason, state} -> {:reply, {:error, reason}, state, :hibernate}
        end

      false ->
        {:reply, {:error, "Command [#{command}] not found for Actor [#{actor_name}]"}, state,
         :hibernate}
    end
  end

  @impl true
  def handle_cast(action, state) do
    state = EntityState.unpack(state)

    do_handle_cast(action, state)
    |> parse_packed_response()
  end

  defp do_handle_cast(
         {:invocation_request,
          %InvocationRequest{
            actor: %Actor{id: %ActorId{name: actor_name} = _id} = _actor,
            command_name: command,
            payload: payload,
            caller: caller
          } = _invocation, opts},
         %EntityState{
           system: actor_system,
           actor: %Actor{state: actor_state, commands: commands, timer_commands: timers}
         } = state
       ) do
    if length(commands) <= 0 do
      Logger.warning("Actor [#{actor_name}] has not registered any Actions")
    end

    all_commands =
      commands ++ Enum.map(timers, fn %FixedTimerCommand{command: cmd} = _timer_cmd -> cmd end)

    case Enum.member?(@default_methods, command) or
           Enum.any?(all_commands, fn cmd -> cmd.name == command end) do
      true ->
        interface = get_interface(actor_system, actor_name, opts)
        current_state = Map.get(actor_state || %{}, :state)

        request =
          ActorInvocation.new(
            actor_name: actor_name,
            actor_system: actor_system,
            command_name: command,
            payload: payload,
            current_context:
              Context.new(
                caller: caller,
                self: ActorId.new(name: actor_name, system: actor_system),
                state: current_state
              ),
            caller: caller
          )

        interface.invoke_host(request, state, @default_methods)
        |> case do
          {:ok, response, state} ->
            do_response(request, response, state)
            {:noreply, state}

          {:error, _reason, state} ->
            {:noreply, state, :hibernate}
        end

      false ->
        {:reply, {:error, "Command [#{command}] not found for Actor [#{actor_name}]"}, state,
         :hibernate}
    end
  end

  @impl true
  def handle_info(action, state) do
    state = EntityState.unpack(state)

    do_handle_info(action, state)
    |> parse_packed_response()
  end

  defp do_handle_info(
         {:invoke_timer_command,
          %FixedTimerCommand{command: %Command{name: cmd} = _command} = timer},
         %EntityState{
           system: _actor_system,
           actor: %Actor{id: caller_actor_id} = actor
         } = state
       ) do
    invocation = %InvocationRequest{
      actor: actor,
      command_name: cmd,
      payload: Noop.new(),
      async: true,
      caller: caller_actor_id
    }

    result = do_handle_cast({:invocation_request, invocation, []}, state)

    :ok = handle_timers([timer])

    result
  end

  defp do_handle_info(
         {:receive, cmd, payload,
          %ActorInvocation{actor_name: caller_actor_name, actor_system: actor_system}},
         %EntityState{
           system: _actor_system,
           actor: %Actor{id: %ActorId{name: actor_name} = _id} = actor
         } = state
       ) do
    Logger.debug(
      "Actor [#{actor_name}] Received Broadcast Event [#{inspect(payload)}] to perform Action [#{cmd}]"
    )

    invocation = %InvocationRequest{
      actor: actor,
      command_name: cmd,
      payload: payload,
      async: true,
      caller: ActorId.new(name: caller_actor_name, system: actor_system)
    }

    do_handle_cast({:invocation_request, invocation, []}, state)
  end

  defp do_handle_info(
         :snapshot,
         %EntityState{
           actor:
             %Actor{
               state: actor_state,
               settings: %ActorSettings{
                 snapshot_strategy: %ActorSnapshotStrategy{
                   strategy: {:timeout, %TimeoutStrategy{timeout: _timeout}} = snapshot_strategy
                 }
               }
             } = _actor
         } = state
       )
       when is_nil(actor_state) or actor_state == %{} do
    schedule_snapshot(snapshot_strategy)
    {:noreply, state, :hibernate}
  end

  defp do_handle_info(
         :snapshot,
         %EntityState{
           state_hash: old_hash,
           actor:
             %Actor{
               id: %ActorId{name: name} = _id,
               state: %ActorState{} = actor_state,
               settings: %ActorSettings{
                 snapshot_strategy: %ActorSnapshotStrategy{
                   strategy: {:timeout, %TimeoutStrategy{timeout: timeout}} = snapshot_strategy
                 }
               }
             } = _actor
         } = state
       ) do
    # Persist State only when necessary
    res =
      if StateManager.is_new?(old_hash, actor_state.state) do
        Logger.debug("Snapshotting actor #{name}")

        # Execute with timeout equals timeout strategy - 1 to avoid mailbox congestions
        case StateManager.save_async(name, actor_state, timeout - 1) do
          {:ok, _, hash} ->
            {:noreply, %{state | state_hash: hash}, :hibernate}

          {:error, _, _, hash} ->
            {:noreply, %{state | state_hash: hash}, :hibernate}

          {:error, :unsuccessfully, hash} ->
            {:noreply, %{state | state_hash: hash}, :hibernate}

          _ ->
            {:noreply, state, :hibernate}
        end
      else
        {:noreply, state, :hibernate}
      end

    schedule_snapshot(snapshot_strategy)
    res
  end

  defp do_handle_info(
         :deactivate,
         %EntityState{
           actor:
             %Actor{
               id: %ActorId{name: name} = _id,
               settings: %ActorSettings{
                 deactivation_strategy:
                   %ActorDeactivationStrategy{strategy: deactivation_strategy} =
                     _actor_deactivation_strategy
               }
             } = _actor
         } = state
       ) do
    case Process.info(self(), :message_queue_len) do
      {:message_queue_len, 0} ->
        Logger.debug("Deactivating actor #{name} for timeout")
        {:stop, :normal, state}

      _ ->
        schedule_deactivate(deactivation_strategy)
        {:noreply, state, :hibernate}
    end
  end

  defp do_handle_info(
         {:EXIT, from, {:name_conflict, {key, value}, registry, pid}},
         %EntityState{
           actor: %Actor{id: %ActorId{} = id}
         } = state
       ) do
    Logger.warning("A conflict has been detected for ActorId #{inspect(id)}. Possible NetSplit!
      Trace Data: [
        from: #{inspect(from)},
        key: #{inspect(key)},
        value: #{inspect(value)},
        registry: #{inspect(registry)},
        pid: #{inspect(pid)}
      ] ")

    {:stop, :normal, state}
  end

  defp do_handle_info(
         {:EXIT, from, reason},
         %EntityState{
           actor: %Actor{id: %ActorId{name: name} = _id}
         } = state
       ) do
    Logger.warning("Received Exit message for Actor #{name} and PID #{inspect(from)}.")

    {:stop, reason, state}
  end

  defp do_handle_info(
         message,
         %EntityState{
           actor: %Actor{id: %ActorId{name: name} = _id, state: actor_state}
         } = state
       )
       when is_nil(actor_state) do
    Logger.warning(
      "No handled internal message for actor #{name}. Message: #{inspect(message)}. Actor state: #{inspect(state)}"
    )

    {:noreply, state, :hibernate}
  end

  defp do_handle_info(
         message,
         %EntityState{
           actor: %Actor{id: %ActorId{name: name} = _id, state: %ActorState{} = actor_state}
         } = state
       ) do
    Logger.warning(
      "No handled internal message for actor #{name}. Message: #{inspect(message)}. Actor state: #{inspect(state)}"
    )

    StateManager.save(name, actor_state)
    {:noreply, state, :hibernate}
  end

  @impl true
  def terminate(action, state) do
    state = EntityState.unpack(state)

    do_terminate(action, state)
  end

  defp do_terminate(
         reason,
         %EntityState{
           actor: %Actor{
             id: %ActorId{name: name} = _id,
             state: actor_state,
             settings: %ActorSettings{persistent: persistent}
           }
         } = _state
       )
       when is_nil(actor_state) or persistent == false do
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  defp do_terminate(
         reason,
         %EntityState{
           actor: %Actor{
             id: %ActorId{name: name} = _id,
             settings: %ActorSettings{persistent: true},
             state: %ActorState{} = actor_state
           }
         } = _state
       ) do
    StateManager.save(name, actor_state)
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  defp do_response(_request, %ActorInvocationResponse{workflow: workflow} = response, _state)
       when is_nil(workflow) or workflow == %{} do
    response
  end

  defp do_response(request, response, state) do
    do_run_workflow(request, response, state)
  end

  defp do_run_workflow(_request, %ActorInvocationResponse{workflow: workflow} = response, _state)
       when is_nil(workflow) or workflow == %{} do
    response
  end

  defp do_run_workflow(
         request,
         %ActorInvocationResponse{
           workflow: %Workflow{broadcast: broadcast, effects: effects} = _workflow
         } = response,
         _state
       ) do
    do_side_effects(effects)
    do_broadcast(request, broadcast)
    do_handle_routing(request, response)
  end

  defp do_handle_routing(
         _request,
         %ActorInvocationResponse{
           workflow: %Workflow{routing: routing} = _workflow
         } = response
       )
       when is_nil(routing),
       do: response

  defp do_handle_routing(
         %ActorInvocation{
           actor_name: caller_actor_name,
           actor_system: system_name
         },
         %ActorInvocationResponse{
           payload: payload,
           workflow:
             %Workflow{
               routing: {:pipe, %Pipe{actor: actor_name, command_name: cmd} = _pipe} = _workflow
             } = response
         }
       ) do
    invocation = %InvocationRequest{
      system: %ActorSystem{name: system_name},
      actor: %Actor{id: ActorId.new(name: actor_name, system: system_name)},
      command_name: cmd,
      payload: payload,
      caller: ActorId.new(name: caller_actor_name, system: system_name)
    }

    try do
      case lookup(system_name, actor_name) do
        {:ok, %HostActor{opts: opts}} ->
          case invoke(invocation, opts) do
            {:ok, response} -> response
            error -> error
          end

        _ ->
          response
      end
    catch
      error ->
        Logger.warning(
          "Error during Pipe request to Actor #{system_name}:#{actor_name}. Error: #{inspect(error)}"
        )

        response
    end
  end

  defp do_handle_routing(
         %ActorInvocation{
           actor_system: system_name,
           payload: payload,
           actor_name: caller_actor_name
         } = _request,
         %ActorInvocationResponse{
           workflow:
             %Workflow{
               routing:
                 {:forward, %Forward{actor: actor_name, command_name: cmd} = _pipe} = _workflow
             } = response
         }
       ) do
    invocation = %InvocationRequest{
      system: %ActorSystem{name: system_name},
      actor: %Actor{id: ActorId.new(name: actor_name, system: system_name)},
      command_name: cmd,
      payload: payload,
      caller: ActorId.new(name: caller_actor_name, system: system_name)
    }

    try do
      case lookup(system_name, actor_name) do
        {:ok, %HostActor{opts: opts}} ->
          case invoke(invocation, opts) do
            {:ok, response} -> response
            error -> error
          end

        _ ->
          response
      end
    catch
      error ->
        Logger.warning(
          "Error during Forward request to Actor #{system_name}:#{actor_name}. Error: #{inspect(error)}"
        )

        response
    end
  end

  def do_broadcast(_request, broadcast) when is_nil(broadcast) or broadcast == %{} do
    :ok
  end

  def do_broadcast(
        request,
        %Broadcast{channel_group: channel, command_name: command, payload: payload} = _broadcast
      ) do
    publish(channel, command, payload, request)
  end

  def do_side_effects(effects) when is_list(effects) and effects == [] do
    :ok
  end

  def do_side_effects(effects) when is_list(effects) do
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
          case lookup(system_name, actor_name) do
            {:ok, %HostActor{opts: opts}} ->
              invoke(invocation, opts)

            _ ->
              :ok
          end
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

  def start_link(%EntityState{actor: %Actor{id: %ActorId{name: name} = _id}} = state) do
    GenServer.start(__MODULE__, state,
      name: via(name),
      spawn_opt: [fullsweep_after: @fullsweep_after]
    )
  end

  @spec get_state(any) :: {:error, term()} | {:ok, term()}
  def get_state(ref) when is_pid(ref) do
    GenServer.call(ref, :get_state, 20_000)
  end

  def get_state(ref) do
    GenServer.call(via(ref), :get_state, 20_000)
  end

  @spec invoke(any, any, any) :: any
  def invoke(ref, request, opts) when is_pid(ref) do
    GenServer.call(ref, {:invocation_request, request, opts}, 30_000)
  end

  def invoke(ref, request, opts) do
    GenServer.call(via(ref), {:invocation_request, request, opts}, 30_000)
  end

  @spec invoke_async(any, any, any) :: :ok
  def invoke_async(ref, request, opts) when is_pid(ref) do
    GenServer.cast(ref, {:invocation_request, request, opts})
  end

  def invoke_async(ref, request, opts) do
    GenServer.cast(via(ref), {:invocation_request, request, opts})
  end

  defp handle_metadata(_actor, metadata) when is_nil(metadata) or metadata == %{} do
    :ok
  end

  defp handle_metadata(actor, %Metadata{channel_group: channel, tags: _tags} = _metadata) do
    :ok = subscribe(actor, channel)
    :ok
  end

  defp publish(channel, command, payload, request) do
    PubSub.broadcast(
      :actor_channel,
      channel,
      {:receive, command, payload, request}
    )
  end

  defp subscribe(_actor, channel) when is_nil(channel), do: :ok

  defp subscribe(actor, channel) do
    Logger.debug("Actor [#{actor}] is subscribing to channel [#{channel}]")
    PubSub.subscribe(:actor_channel, channel)
  end

  defp get_interface(system_name, actor_name, opts),
    do:
      Keyword.get(
        opts,
        :host_interface,
        get_interface_by_actor_or_default(system_name, actor_name)
      )

  defp get_interface_by_actor_or_default(system_name, actor_name) do
    case lookup(system_name, actor_name) do
      {:ok, %HostActor{opts: opts}} ->
        Keyword.get(opts, :host_interface, @default_host_interface)

      _ ->
        @default_host_interface
    end
  end

  defp get_timeout_factor(factor_range) when is_number(factor_range),
    do: Enum.random([factor_range])

  defp get_timeout_factor(factor_range) when is_list(factor_range), do: Enum.random(factor_range)

  defp get_timeout_factor(factor_range), do: Enum.random(factor_range)

  defp schedule_snapshot_advance(timeout),
    do:
      Process.send_after(
        self(),
        :snapshot,
        timeout
      )

  defp schedule_snapshot(snapshot_strategy, timeout_factor \\ 0),
    do:
      Process.send_after(
        self(),
        :snapshot,
        get_snapshot_interval(snapshot_strategy, timeout_factor)
      )

  defp schedule_deactivate(deactivation_strategy, timeout_factor \\ 0),
    do:
      Process.send_after(
        self(),
        :deactivate,
        get_deactivate_interval(deactivation_strategy, timeout_factor)
      )

  defp get_snapshot_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor
       )
       when is_nil(timeout),
       do: @default_snapshot_timeout + timeout_factor

  defp get_snapshot_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor
       ),
       do: timeout + timeout_factor

  defp get_deactivate_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor
       )
       when is_nil(timeout),
       do: @default_deactivate_timeout + timeout_factor

  defp get_deactivate_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor
       ),
       do: timeout + timeout_factor

  defp handle_timers(timers) when is_list(timers) do
    if length(timers) > 0 do
      timers
      |> Stream.map(fn %FixedTimerCommand{seconds: delay} = timer_command ->
        Process.send_after(self(), {:invoke_timer_command, timer_command}, delay)
      end)
      |> Stream.run()
    end

    :ok
  catch
    error -> Logger.error("Error on handle timers #{inspect(error)}")
  end

  defp handle_timers(nil), do: :ok

  defp handle_timers([]), do: :ok

  defp parse_packed_response(response) do
    case response do
      {:reply, response, state} -> {:reply, response, EntityState.pack(state)}
      {:reply, response, state, opts} -> {:reply, response, EntityState.pack(state), opts}
      {:stop, reason, state, opts} -> {:stop, reason, EntityState.pack(state), opts}
      {:stop, reason, state} -> {:stop, reason, EntityState.pack(state)}
      {:noreply, state} -> {:noreply, EntityState.pack(state)}
      {:noreply, state, opts} -> {:noreply, EntityState.pack(state), opts}
      {:ok, state} -> {:ok, EntityState.pack(state)}
      {:ok, state, opts} -> {:ok, EntityState.pack(state), opts}
    end
  end

  defp via(name) do
    {:via, Horde.Registry, {Spawn.Cluster.Node.Registry, {__MODULE__, name}}}
  end
end
