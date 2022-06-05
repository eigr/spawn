defmodule Eigr.Functions.Protocol.Actors.ActorEntity do
  use GenServer, restart: :transient
  require Logger

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorDeactivateStrategy,
    ActorState,
    ActorSnapshotStrategy,
    ActorSystem,
    StateManager,
    TimeoutStrategy
  }

  alias Eigr.Functions.Protocol.{
    ActorInvocation,
    ActorInvocationResponse,
    InvocationRequest
  }

  alias Spawn.Proxy.NodeManager

  @min_snapshot_threshold 500
  @default_snapshot_timeout 60_000
  @default_deactivate_timeout 90_000
  @timeout_factor_range [200, 300, 500, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000]

  defmodule EntityState do
    defstruct system: nil, actor: nil, state_hash: nil

    @type t(system, actor, state_hash) :: %EntityState{
            system: system,
            actor: actor,
            state_hash: state_hash
          }

    @type t :: %EntityState{system: ActorSystem.t(), actor: Actor.t(), state_hash: binary()}
  end

  @impl true
  @spec init(EntityState.t()) ::
          {:ok, EntityState.t(), {:continue, :load_state}}
  def init(
        %EntityState{
          actor: %Actor{
            name: name,
            snapshot_strategy: %ActorSnapshotStrategy{strategy: snapshot_strategy},
            deactivate_strategy: %ActorDeactivateStrategy{strategy: deactivate_strategy}
          }
        } = state
      ) do
    Logger.debug("Activating actor #{name} in Node #{inspect(Node.self())}")
    Process.flag(:trap_exit, true)

    schedule_deactivate(deactivate_strategy, get_timeout_factor(@timeout_factor_range))

    # Write soon in the first time
    schedule_snapshot_advance(@min_snapshot_threshold + get_timeout_factor(@timeout_factor_range))
    {:ok, state, {:continue, :load_state}}
  end

  @impl true
  @spec handle_continue(:load_state, EntityState.t()) :: {:noreply, EntityState.t()}
  def handle_continue(
        :load_state,
        %EntityState{
          actor: %Actor{name: name, state: actor_state} = actor
        } = state
      )
      when is_nil(actor_state) do
    Logger.debug("Initial state is empty... Getting state from state manager.")

    case StateManager.load(name) do
      {:ok, current_state} ->
        {:noreply, %EntityState{state | actor: %Actor{actor | state: current_state}}}

      {:not_found, %{}} ->
        Logger.debug("Not found initial Actor State on statestore for Actor #{name}.")
        {:noreply, state}
    end
  end

  def handle_continue(
        :load_state,
        %EntityState{
          actor: %Actor{name: name, state: %ActorState{} = actor_state} = actor
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
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(
        :get_state,
        _from,
        %EntityState{
          actor: %Actor{name: name, state: actor_state} = actor
        } = state
      )
      when is_nil(actor_state),
      do: {:reply, nil, state}

  def handle_call(
        :get_state,
        _from,
        %EntityState{
          actor: %Actor{name: name, state: %ActorState{} = actor_state} = actor
        } = state
      ),
      do: {:reply, actor_state, state}

  def handle_call(
        {:actor_invocation_response, %ActorInvocationResponse{} = invocation},
        _from,
        %EntityState{
          system: %ActorSystem{name: actor_system} = _system,
          actor: %Actor{name: name, state: %ActorState{} = actor_state} = _actor
        } = state
      ) do
    {:reply, %{}, state}
  end

  @impl true
  def handle_cast(
        {:invocation_request,
         %InvocationRequest{
           actor: %Actor{name: name} = actor,
           command_name: command,
           value: payload
         } = invocation},
        %EntityState{
          system: %ActorSystem{name: actor_system} = _system
        } = state
      ) do
    payload = ActorInvocation.new(invocation_request: invocation)
    NodeManager.invoke_user_function(actor_system, payload)
    {:noreply, state}
  end

  @impl true
  def handle_info(
        :snapshot,
        %EntityState{
          actor:
            %Actor{
              state: actor_state,
              snapshot_strategy: %ActorSnapshotStrategy{
                strategy: {:timeout, %TimeoutStrategy{timeout: timeout}} = snapshot_strategy
              }
            } = _actor
        } = state
      )
      when is_nil(actor_state) or actor_state == %{} do
    schedule_snapshot(snapshot_strategy)
    {:noreply, state}
  end

  def handle_info(
        :snapshot,
        %EntityState{
          state_hash: old_hash,
          actor:
            %Actor{
              name: name,
              state: %ActorState{} = actor_state,
              snapshot_strategy: %ActorSnapshotStrategy{
                strategy: {:timeout, %TimeoutStrategy{timeout: timeout}} = snapshot_strategy
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
            {:noreply, %{state | state_hash: hash}}

          {:error, _, _, hash} ->
            {:noreply, %{state | state_hash: hash}}

          {:error, :unsuccessfully, hash} ->
            {:noreply, %{state | state_hash: hash}}

          _ ->
            {:noreply, state}
        end
      else
        {:noreply, state}
      end

    schedule_snapshot(snapshot_strategy)
    res
  end

  def handle_info(
        :deactivate,
        %EntityState{
          actor:
            %Actor{
              name: name,
              deactivate_strategy:
                %ActorDeactivateStrategy{strategy: deactivate_strategy} =
                  _actor_deactivate_strategy
            } = _actor
        } = state
      ) do
    case Process.info(self(), :message_queue_len) do
      {:message_queue_len, 0} ->
        Logger.debug("Deactivating actor #{name} for timeout")
        {:stop, :normal, state}

      _ ->
        schedule_deactivate(deactivate_strategy)
        {:noreply, state}
    end
  end

  def handle_info(
        message,
        %EntityState{
          actor: %Actor{name: name, state: actor_state}
        } = state
      )
      when is_nil(actor_state) do
    Logger.warn("No handled internal message for actor #{name}. Message: #{inspect(message)}")
    {:noreply, state}
  end

  def handle_info(
        message,
        %EntityState{
          actor: %Actor{name: name, state: %ActorState{} = actor_state}
        } = state
      ) do
    Logger.warn("No handled internal message for actor #{name}. Message: #{inspect(message)}")
    StateManager.save(name, actor_state)
    {:noreply, state}
  end

  @impl true
  def terminate(reason, %EntityState{actor: %Actor{name: name, state: actor_state}} = _state)
      when is_nil(actor_state) do
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def terminate(
        reason,
        %EntityState{actor: %Actor{name: name, state: %ActorState{} = actor_state}} = _state
      ) do
    StateManager.save(name, actor_state)
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def start_link(%EntityState{actor: %Actor{name: name}} = state) do
    GenServer.start(__MODULE__, state, name: via(name))
  end

  def get_state(name) do
    GenServer.call(via(name), :get_state, 20_000)
  end

  def invoke(name, request) do
    GenServer.cast(via(name), {:invocation_request, request})
  end

  def invoke_async(name, request) do
    GenServer.cast(via(name), {:invocation_request, :async, request})
  end

  defp get_timeout_factor(factor_range) when is_number(factor_range),
    do: Enum.random([factor_range])

  defp get_timeout_factor(factor_range) when is_list(factor_range), do: Enum.random(factor_range)

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

  defp get_snapshot_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor \\ 0
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
         timeout_factor \\ 0
       )
       when is_nil(timeout),
       do: @default_deactivate_timeout + timeout_factor

  defp get_deactivate_interval(
         {:timeout, %TimeoutStrategy{timeout: timeout}} = _timeout_strategy,
         timeout_factor
       ),
       do: timeout + timeout_factor

  defp via(name) do
    {:via, Horde.Registry, {Spawn.Actor.Registry, {__MODULE__, name}}}
  end
end
