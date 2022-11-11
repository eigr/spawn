defmodule Actors.Actor.Entity do
  use GenServer, restart: :transient
  require Logger

  alias Actors.Actor.StateManager
  alias Actors.Actor.Entity.{EntityState, Lifecycle, Invocation}

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorState
  }

  @fullsweep_after 10

  @impl true
  @spec init(EntityState.t()) ::
          {:ok, EntityState.t(), {:continue, :load_state}}
  def init(initial_state) do
    initial_state
    |> EntityState.unpack()
    |> Lifecycle.init()
    |> parse_packed_response()
  end

  @impl true
  @spec handle_continue(atom(), EntityState.t()) :: {:noreply, EntityState.t()}
  def handle_continue(action, state) do
    state = EntityState.unpack(state)

    case action do
      :load_state ->
        Lifecycle.load_state(state)

      :call_init_action ->
        Invocation.invoke_init(state)

      action ->
        do_handle_continue(action, state)
    end
    |> parse_packed_response()
  end

  defp do_handle_continue(action, state) do
    Logger.warning("Unhandled handle_continue for action #{action}")

    {:noreply, state, :hibernate}
  end

  @impl true
  def handle_call(action, from, state) do
    state = EntityState.unpack(state)

    case action do
      {:invocation_request, invocation, opts} -> Invocation.invoke({invocation, opts}, state)
      action -> do_handle_call(action, from, state)
    end
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

  @impl true
  def handle_cast(action, state) do
    state = EntityState.unpack(state)

    case action do
      {:invocation_request, invocation, opts} ->
        Invocation.invoke({invocation, opts}, state) |> reply_to_noreply()

      action ->
        do_handle_cast(action, state)
    end
    |> parse_packed_response()
  end

  defp do_handle_cast(action, state) do
    Logger.warning("Unhandled handle_cast for action #{action}")

    {:noreply, state, :hibernate}
  end

  @impl true
  def handle_info(action, state) do
    state = EntityState.unpack(state)

    case action do
      :snapshot ->
        Lifecycle.snapshot(state)

      :deactivate ->
        Lifecycle.deactivate(state)

      {:invoke_timer_command, command} ->
        Invocation.timer_invoke(command, state)

      {:receive, cmd, payload, invocation} ->
        Invocation.broadcast_invoke(cmd, payload, invocation, state)

      {:receive, payload} ->
        Invocation.broadcast_invoke(payload, state)

      action ->
        do_handle_info(action, state)
    end
    |> parse_packed_response()
  end

  defp do_handle_info(
         {:EXIT, from, {:name_conflict, {key, value}, registry, pid}},
         %EntityState{
           actor: %Actor{id: %ActorId{} = id}
         } = state
       ) do
    Logger.warning(
      "A conflict has been detected for ActorId #{inspect(id)}. Possible Actor Rebalance or NetSplit!
      Trace Data: [
        from: #{inspect(from)},
        key: #{inspect(key)},
        value: #{inspect(value)},
        registry: #{inspect(registry)},
        pid: #{inspect(pid)}
      ] "
    )

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
       ) do
    Logger.warning(
      "No handled internal message for actor #{name}. Message: #{inspect(message)}. Actor state: #{inspect(state)}"
    )

    if not is_nil(actor_state), do: StateManager.save(name, actor_state)

    {:noreply, state, :hibernate}
  end

  @impl true
  def terminate(action, state) do
    state = EntityState.unpack(state)

    Lifecycle.terminate(action, state)
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

  defp reply_to_noreply({:reply, _response, state}), do: {:noreply, state}
  defp reply_to_noreply({:reply, _response, state, opts}), do: {:noreply, state, opts}

  defp via(name) do
    {:via, Horde.Registry, {Spawn.Cluster.Node.Registry, {__MODULE__, name}}}
  end
end
