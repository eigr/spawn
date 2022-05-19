defmodule Eigr.Functions.Protocol.Actors.ActorEntity do
  use GenServer, restart: :transient
  require Logger

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorState,
    ActorDeactivateStrategy,
    ActorSnapshotStrategy,
    StateManager,
    TimeoutStrategy
  }

  alias Eigr.Functions.Protocol.Actors.ActorEntity.Supervisor, as: ActorEntitySupervisor

  alias Eigr.Functions.Protocol.{
    ActorInvocation,
    InvocationRequest
  }

  @default_snapshot_timeout 60_000
  @default_deactivate_timeout 90_000

  @impl true
  @spec init(Eigr.Functions.Protocol.Actors.Actor.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.Actor.t(), {:continue, :load_state}}
  def init(
        %Actor{
          name: name,
          snapshot_strategy: %ActorSnapshotStrategy{strategy: snapshot_strategy},
          deactivate_strategy: %ActorDeactivateStrategy{strategy: deactivate_strategy}
        } = state
      ) do
    Logger.debug("Activating actor #{name} in Node #{inspect(Node.self())}")
    Process.flag(:trap_exit, true)
    schedule_snapshot(snapshot_strategy)
    schedule_deactivate(deactivate_strategy)

    {:ok, state, {:continue, :load_state}}
  end

  @impl true
  def handle_call(:get_state, _from, %Actor{actor_state: %ActorState{} = actor_state} = state) do
    {:reply, actor_state, state}
  end

  def handle_call(
        {:invocation_request,
         %InvocationRequest{
           actor: %Actor{name: name} = actor,
           command_name: command,
           value: payload
         } = invocation},
        _from,
        %Actor{actor_state: %ActorState{} = actor_state} = state
      ) do
    # TODO: Use ActorInvocation to pass request to real actor
    {:reply, %{}, state}
  end

  @impl true
  @spec handle_continue(:load_state, Eigr.Functions.Protocol.Actors.Actor.t()) ::
          {:noreply, Eigr.Functions.Protocol.Actors.Actor.t()}
  def handle_continue(:load_state, %Actor{actor_state: nil} = state) do
    Logger.debug("Initial state is empty... Getting state from state manager.")

    {:ok, current_state} = StateManager.load(state.name)
    {:noreply, %Actor{state | actor_state: current_state}}
  end

  def handle_continue(:load_state, %Actor{actor_state: %ActorState{} = actor_state} = state) do
    Logger.debug(
      "Initial state is not empty... Trying to reconcile the state with state manager."
    )

    {:ok, _current_state} = StateManager.load(state.name)

    # TODO: Check if the state is empty in the state manager. If so, then set state from initial state.
    updated_state = actor_state
    {:noreply, %Actor{state | actor_state: updated_state}}
  end

  @impl true
  def handle_info(
        :snapshot,
        %Actor{
          name: _name,
          snapshot_strategy: %ActorSnapshotStrategy{strategy: snapshot_strategy},
          actor_state: nil
        } = state
      ) do
    schedule_snapshot(snapshot_strategy)
    {:noreply, state}
  end

  def handle_info(
        :snapshot,
        %Actor{
          name: name,
          snapshot_strategy: %ActorSnapshotStrategy{strategy: snapshot_strategy},
          actor_state: %ActorState{} = actor_state
        } = state
      ) do
    Logger.debug("Snapshotting actor #{name}")
    StateManager.save(name, actor_state)
    schedule_snapshot(snapshot_strategy)
    {:noreply, state}
  end

  def handle_info(
        :deactivate,
        %Actor{
          name: name,
          deactivate_strategy:
            %ActorDeactivateStrategy{strategy: deactivate_strategy} = _actor_deactivate_strategy
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

  @impl true
  def terminate(reason, %Actor{name: name, actor_state: %ActorState{} = actor_state} = _state) do
    StateManager.save(name, actor_state)
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def start_link(%Actor{name: name} = actor) do
    GenServer.start(__MODULE__, actor, name: via(name))
  end

  def get_state(name) do
    GenServer.call(via(name), :get_state, 20_000)
  end

  def invoke_sync(name, request) do
    GenServer.call(via(name), {:invocation_request, request}, 20_000)
  end

  def invoke_async(name, request) do
    GenServer.call(via(name), {:invocation_request, request}, 20_000)
  end

  defp schedule_snapshot(snapshot_strategy),
    do: Process.send_after(self(), :snapshot, get_snapshot_interval(snapshot_strategy))

  defp schedule_deactivate(deactivate_strategy),
    do: Process.send_after(self(), :deactivate, get_deactivate_interval(deactivate_strategy))

  defp get_snapshot_interval(%TimeoutStrategy{timeout: timeout} = _timeout_strategy)
       when is_nil(timeout),
       do: @default_snapshot_timeout

  defp get_snapshot_interval(%TimeoutStrategy{timeout: timeout} = _timeout_strategy),
    do: timeout

  defp get_deactivate_interval(%TimeoutStrategy{timeout: timeout} = _timeout_strategy)
       when is_nil(timeout),
       do: @default_deactivate_timeout

  defp get_deactivate_interval(%TimeoutStrategy{timeout: timeout} = _timeout_strategy),
    do: timeout

  defp via(name) do
    {:via, Horde.Registry, {Spawn.Actor.Registry, {__MODULE__, name}}}
  end
end
