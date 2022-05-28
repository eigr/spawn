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

  alias Eigr.Functions.Protocol.Actors.ActorEntity.Supervisor, as: ActorEntitySupervisor

  alias Eigr.Functions.Protocol.{
    ActorInvocation,
    ActorInvocationResponse,
    InvocationRequest
  }

  alias Spawn.Proxy.NodeManager

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
  @spec handle_continue(:load_state, Eigr.Functions.Protocol.Actors.Actor.t()) ::
          {:noreply, Eigr.Functions.Protocol.Actors.Actor.t()}
  def handle_continue(:load_state, %Actor{name: name, state: nil} = state) do
    Logger.debug("Initial state is empty... Getting state from state manager.")

    case StateManager.load(name) do
      {:ok, current_state} ->
        {:noreply, %Actor{state | state: current_state}}

      {:not_found, %{}} ->
        Logger.debug("Not found initial Actor State on statestore for Actor #{name}.")
        {:noreply, state}
    end
  end

  def handle_continue(:load_state, %Actor{name: name, state: %ActorState{} = actor_state} = state) do
    Logger.debug(
      "Initial state is not empty... Trying to reconcile the state with state manager."
    )

    case StateManager.load(name) do
      {:ok, current_state} ->
        # TODO: Merge current with old ?
        {:noreply, %Actor{state | state: current_state}}

      {:not_found, %{}} ->
        Logger.debug("Not found initial on statestore for Actor #{name}.")
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(
        :get_state,
        _from,
        %Actor{name: name, state: %ActorState{} = actor_state} = state
      ),
      do: {:reply, state, state}

  def handle_call(
        {:actor_invocation_response, %ActorInvocationResponse{} = invocation},
        _from,
        %Actor{
          state: %ActorState{} = actor_state,
          system: %ActorSystem{name: actor_system} = _system
        } = state
      ) do
    {:reply, %{}, state}
  end

  def handle_cast(
        {:invocation_request,
         %InvocationRequest{
           from: %Actor{name: name} = from_actor,
           target: %Actor{name: name} = target_actor,
           command_name: command,
           value: payload
         } = invocation},
        %Actor{
          state: %ActorState{} = actor_state,
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
        %Actor{
          name: _name,
          snapshot_strategy: %ActorSnapshotStrategy{strategy: snapshot_strategy},
          state: nil
        } = state
      ) do
    schedule_snapshot(snapshot_strategy)
    {:noreply, state}
  end

  def handle_info(
        :snapshot,
        %Actor{
          name: name,
          snapshot_strategy: %ActorSnapshotStrategy{
            strategy: %TimeoutStrategy{timeout: timeout} = snapshot_strategy
          },
          state: %ActorState{} = actor_state
        } = state
      ) do
    Logger.debug("Snapshotting actor #{name}")

    # Execute with timeout equals timeout strategy - 1 to avoid mailbox congestions
    StateManager.save_async(name, actor_state, timeout - 1)
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

  def handle_info(message, %Actor{name: name} = state) do
    Logger.warn("No handled internal message for actor #{name}. Message: #{inspect(message)}")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, %Actor{name: name, state: actor_state} = _state)
      when is_nil(actor_state) do
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def terminate(reason, %Actor{name: name, state: %ActorState{} = actor_state} = _state) do
    StateManager.save(name, actor_state)
    Logger.debug("Terminating actor #{name} with reason #{inspect(reason)}")
  end

  def start_link(%Actor{name: name} = actor) do
    GenServer.start(__MODULE__, actor, name: via(name))
  end

  def get_state(name) do
    GenServer.call(via(name), :get_state, 20_000)
  end

  def invoke(name, request) do
    GenServer.cast(via(name), {:invocation_request, request}, 20_000)
  end

  def invoke_async(name, request) do
    GenServer.cast(via(name), {:invocation_request, :async, request}, 20_000)
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
