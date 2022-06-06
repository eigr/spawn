defmodule Actors.Node.NodeManager do
  use GenServer
  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorSystem}
  alias Actors.Actor.Entity.Supervisor, as: ActorEntitySupervisor
  alias Eigr.Functions.Protocol.ActorService.Stub, as: ActorServiceClient

  alias Eigr.Functions.Protocol.{ProxyInfo, RegistrationResponse}

  @spec init(any) :: {:ok, any}
  def init(%{source_stream: %{payload: %{pid: connection_ref}} = stream} = state) do
    IO.inspect(stream, label: "Source Stream")
    Logger.debug("Monitoring connection #{inspect(connection_ref)} with UserFunction.")
    Process.monitor(connection_ref)
    Process.flag(:trap_exit, true)
    Process.send_after(self(), :keepalive, 1000)
    {:ok, state}
  end

  @impl true
  def handle_info(
        {:DOWN, _, _, _, reason},
        %{source_stream: %{payload: %{pid: connection_ref}}} = state
      ) do
    IO.inspect(state, label: "Source Stream")

    Logger.info(
      "Stream closed with reason #{inspect(reason)} for connection #{inspect(connection_ref)}."
    )

    {:stop, :normal, state}
  end

  def handle_info(:keepalive, %{actor_system: name, source_stream: stream} = state) do
    GRPC.Server.send_reply(
      stream,
      RegistrationResponse.new(proxy_info: ProxyInfo.new())
    )

    Process.send_after(self(), :keepalive, 1000)
    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:invoke_user_function, payload},
        %{source_stream: stream} = state
      ) do
    Logger.debug("Calling User Function with Payload: #{inspect(payload)}")
    GRPC.Server.send_reply(stream, payload)

    {:noreply, state}
  end

  @impl true
  def handle_call(
        {:try_reactivate, {%ActorSystem{} = system, %Actor{name: name} = actor}},
        _from,
        state
      ) do
    Logger.debug("Trying reactivating Actor #{name}...")

    case ActorEntitySupervisor.lookup_or_create_actor(system, actor) do
      {:ok, pid} ->
        Logger.debug("Actor #{name} reactivated.")
        {:reply, {:ok, pid}, state}

      reason ->
        Logger.error("Failed to reactivate actor #{name}: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def terminate(reason, %{source_stream: %{payload: %{pid: connection_ref} = stream}} = state) do
    Logger.debug(
      "Terminating NodeManager because connection stream #{inspect(connection_ref)} is droped. Terminating reason is #{inspect(reason)}"
    )
  end

  def start_link(
        %{actor_system: system_name, source_stream: %{payload: %{pid: connection_ref}}} = state
      ) do
    GenServer.start(__MODULE__, state, name: via(system_name))
  end

  def invoke_user_function(actor_system, payload) do
    GenServer.cast(via(actor_system), {:invoke_user_function, payload})
  end

  def try_reactivate_actor(%ActorSystem{name: system_name} = system, actor) do
    GenServer.call(via(system_name), {:try_reactivate, {system, actor}})
  end

  defp via(name) do
    {:via, Registry, {Actors.NodeRegistry, {__MODULE__, name}}}
  end
end
