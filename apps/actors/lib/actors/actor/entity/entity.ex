defmodule Actors.Actor.Entity do
  use GenServer, restart: :transient
  require Logger

  alias Actors.Actor.{Entity.EntityState, StateManager}

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorDeactivateStrategy,
    ActorSettings,
    ActorState,
    ActorSnapshotStrategy,
    TimeoutStrategy
  }

  alias Eigr.Functions.Protocol.{
    Context,
    ActorInvocation,
    InvocationRequest
  }

  @default_deactivate_timeout 90_000

  @default_methods [
    "get",
    "Get",
    "get_state",
    "getState",
    "GetState"
  ]

  @default_snapshot_timeout 60_000

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
             settings:
               %ActorSettings{persistent: false, deactivate_strategy: deactivate_strategy} =
                 _settings
           }
         } = state
       )
       when is_nil(deactivate_strategy) or deactivate_strategy == %{} do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence disabled."
    )

    strategy = {:timeout, TimeoutStrategy.new!(timeout: @default_deactivate_timeout)}
    schedule_deactivate(strategy, get_timeout_factor(@timeout_factor_range))
    {:ok, state}
  end

  defp do_init(
         %EntityState{
           actor: %Actor{
             id: %ActorId{name: name} = _id,
             settings:
               %ActorSettings{
                 persistent: false,
                 deactivate_strategy:
                   %ActorDeactivateStrategy{strategy: deactivate_strategy} = _dstrategy
               } = _settings
           }
         } = state
       ) do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence disabled."
    )

    schedule_deactivate(deactivate_strategy, get_timeout_factor(@timeout_factor_range))
    {:ok, state}
  end

  defp do_init(
         %EntityState{
           actor: %Actor{
             id: %ActorId{name: name} = _id,
             settings:
               %ActorSettings{
                 persistent: true,
                 snapshot_strategy: %ActorSnapshotStrategy{} = _snapshot_strategy,
                 deactivate_strategy: deactivate_strategy
               } = _settings
           }
         } = state
       )
       when is_nil(deactivate_strategy) or deactivate_strategy == %{} do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence enabled."
    )

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
             settings:
               %ActorSettings{
                 persistent: true,
                 snapshot_strategy: %ActorSnapshotStrategy{} = _snapshot_strategy,
                 deactivate_strategy: %ActorDeactivateStrategy{strategy: deactivate_strategy}
               } = _settings
           }
         } = state
       ) do
    Process.flag(:trap_exit, true)

    Logger.notice(
      "Activating actor #{name} in Node #{inspect(Node.self())}. Persistence enabled."
    )

    schedule_deactivate(deactivate_strategy, get_timeout_factor(@timeout_factor_range))

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
            actor: %Actor{id: %ActorId{name: name} = _id} = _actor,
            command_name: command,
            value: payload
          } = _invocation, opts},
         _from,
         %EntityState{
           system: actor_system,
           actor: %Actor{state: actor_state}
         } = state
       ) do
    interface = get_interface(opts)
    current_state = Map.get(actor_state || %{}, :state)

    ActorInvocation.new(
      actor_name: name,
      actor_system: actor_system,
      command_name: command,
      value: payload,
      current_context: Context.new(state: current_state)
    )
    |> interface.invoke_host(state, @default_methods)
    |> case do
      {:ok, response, state} -> {:reply, {:ok, response}, state}
      {:error, reason, state} -> {:reply, {:error, reason}, state, :hibernate}
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
            actor: %Actor{id: %ActorId{name: name} = _id} = _actor,
            command_name: command,
            value: payload
          } = _invocation, opts},
         %EntityState{
           system: actor_system,
           actor: %Actor{state: actor_state}
         } = state
       ) do
    interface = get_interface(opts)
    current_state = Map.get(actor_state || %{}, :state)

    ActorInvocation.new(
      actor_name: name,
      actor_system: actor_system,
      command_name: command,
      value: payload,
      current_context: Context.new(state: current_state)
    )
    |> interface.invoke_host(state, @default_methods)
    |> case do
      {:ok, _whatever, state} -> {:noreply, state}
      {:error, _reason, state} -> {:noreply, state, :hibernate}
    end
  end

  @impl true
  def handle_info(action, state) do
    state = EntityState.unpack(state)

    do_handle_info(action, state)
    |> parse_packed_response()
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
                 deactivate_strategy:
                   %ActorDeactivateStrategy{strategy: deactivate_strategy} =
                     _actor_deactivate_strategy
               }
             } = _actor
         } = state
       ) do
    case Process.info(self(), :message_queue_len) do
      {:message_queue_len, 0} ->
        Logger.debug("Deactivating actor #{name} for timeout")
        {:stop, :normal, state}

      _ ->
        schedule_deactivate(deactivate_strategy)
        {:noreply, state, :hibernate}
    end
  end

  defp do_handle_info(
         {:EXIT, pid, reason},
         %EntityState{
           actor: %Actor{id: %ActorId{name: name} = _id}
         } = state
       ) do
    Logger.warning("Received Exit message for Actor #{name} and PID #{inspect(pid)}.")

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

  defp get_interface(opts), do: Keyword.get(opts, :host_interface, Actors.Actor.Interface.Http)

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

  defp schedule_deactivate(deactivate_strategy, timeout_factor \\ 0),
    do:
      Process.send_after(
        self(),
        :deactivate,
        get_deactivate_interval(deactivate_strategy, timeout_factor)
      )

  defp get_snapshot_interval(timeout_strategy, timeout_factor \\ 0)

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

  defp get_deactivate_interval(timeout_strategy, timeout_factor \\ 0)

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
