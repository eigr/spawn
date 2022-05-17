defmodule Spawn.Proxy.NodeManager do
  use GenServer
  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorEntity}
  alias Eigr.Functions.Protocol.ActorService.Stub, as: ActorServiceClient

  @spec init(any) :: {:ok, any}
  def init(%{source_stream: %{payload: %{pid: connection_ref}} = _stream} = state) do
    Logger.debug("Monitoring connection #{inspect(connection_ref)} with UserFunction.")
    Process.monitor(connection_ref)
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  @impl true
  def handle_info(
        {:DOWN, _, _, _, reason},
        %{source_stream: %{payload: %{pid: connection_ref}}} = state
      ) do
    Logger.info(
      "Stream closed with reason #{inspect(reason)} for connection #{inspect(connection_ref)}."
    )

    {:stop, :normal, state}
  end

  @impl true
  def handle_call(
        {:invoke_user_function, payload},
        _from,
        %{source_stream: %{payload: %{pid: connection_ref} = stream}} = state
      ) do
    response = GRPC.Server.send_reply(stream, payload)
    {:reply, response, state}
  end

  @impl true
  def handle_call({:try_reactivate_actor, %Actor{name: name} = actor}, _from, state) do
    Logger.debug("Trying reactivating Actor #{name}...")

    case ActorEntity.lookup_or_create_actor(actor) do
      {:ok, pid} ->
        Logger.debug("Actor #{name} reactivated.")
        {:reply, {:ok, pid}, state}

      reason ->
        Logger.error("Failed to reactivate actor #{name}: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  def start_link(
        %{actor_system: system_name, source_stream: %{payload: %{pid: connection_ref}}} = state
      ) do
    GenServer.start(__MODULE__, state, name: via(system_name))
  end

  def invoke_user_function(actor_system, payload) do
    GenServer.call(via(actor_system), {:invoke_user_function, payload})
  end

  def try_reactivate(actor_system, actor) do
    GenServer.call(via(actor_system), {:try_reactivate_actor, actor})
  end

  defp via(name) do
    {:via, Registry, {Spawn.NodeRegistry, {__MODULE__, name}}}
  end
end
