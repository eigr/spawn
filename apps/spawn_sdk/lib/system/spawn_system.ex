defmodule SpawnSdk.System.SpawnSystem do
  @moduledoc """
  `SpawnSystem`
  """
  use GenServer
  require Logger

  @behaviour SpawnSdk.System

  alias Actors

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorState,
    ActorDeactivateStrategy,
    ActorSnapshotStrategy,
    ActorSystem,
    Registry,
    TimeoutStrategy
  }

  alias Eigr.Functions.Protocol.{
    InvocationRequest,
    RegistrationRequest,
    RegistrationResponse,
    RequestStatus,
    ServiceInfo,
    SpawnRequest,
    SpawnResponse
  }

  @app :spawn_sdk
  @service_name "spawn-elixir"
  @service_version Application.spec(@app)[:vsn]
  @service_runtime "elixir #{System.version()}"
  @support_library_name "spawn-elixir-sdk"
  @support_library_version @service_version

  @impl true
  def init(state) do
    system = Keyword.fetch!(state, :system)
    actors = Keyword.fetch!(state, :actors)

    case do_register(system, actors) do
      :ok ->
        {:ok, state}

      {:error, msg} ->
        raise msg
    end
  end

  @impl true
  def handle_call({:register, system, actors}, from, state) do
    spawn(fn ->
      GenServer.reply(from, do_register(system, actors))
    end)

    {:noreply, state}
  end

  def handle_call({:invoke, actor, command, payload, options}, from, state) do
    spawn(fn ->
      GenServer.reply(from, do_invoke(actor, command, payload, options))
    end)

    {:noreply, state}
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl SpawnSdk.System
  def register(system, actors) do
    GenServer.call(__MODULE__, {:register, system, actors}, 20_000)
  end

  @impl SpawnSdk.System
  def invoke(actor, command, payload, options) do
    call_timeout = Keyword.get(options, :timeout, 20_000)
    GenServer.call(__MODULE__, {:invoke, actor, command, payload, options}, call_timeout)
  end

  defp do_register(system, actors) do
    opts = [host_interface: SpawnSdk.Interface]

    case Actors.register(build_registration_req(system, actors), opts) do
      {:ok, %RegistrationResponse{proxy_info: proxy_info, status: status}} ->
        Logger.debug(
          "Actors registration succed. Proxy info: #{inspect(proxy_info)}. Status: #{inspect(status)}"
        )

        :ok

      error ->
        {:error, "Actors registration failed. Error #{inspect(error)}"}
    end
  end

  defp do_invoke(_actor, _command, _payload, options) do
    _async = Keyword.get(options, :async, false)
    _input_type = Keyword.fetch!(options, :input_type)
    _output_type = Keyword.fetch!(options, :output_type)
    # Actors.invoke()
    :ok
  end

  defp build_registration_req(system, actors) do
    req =
      RegistrationRequest.new(
        service_info:
          ServiceInfo.new(
            service_name: @service_name,
            service_version: @service_version,
            service_runtime: @service_runtime,
            support_library_name: @support_library_name,
            support_library_version: @support_library_version
          ),
        actor_system:
          ActorSystem.new(
            name: system,
            registry: %Registry{actors: to_map(actors)}
          )
      )

    req
  end

  defp to_map(actors) do
    actors
    |> Enum.into(%{}, fn actor ->
      name = actor.__meta__(:name)
      persistent = actor.__meta__(:persistent)
      snapshot_timeout = actor.__meta__(:snapshot_timeout)
      deactivate_timeout = actor.__meta__(:deactivate_timeout)

      snapshot_strategy =
        ActorSnapshotStrategy.new(
          strategy: {:timout, TimeoutStrategy.new(timeout: snapshot_timeout)}
        )

      deactivate_strategy =
        ActorDeactivateStrategy.new(
          strategy: {:timout, TimeoutStrategy.new(timeout: deactivate_timeout)}
        )

      {name,
       Actor.new(
         name: name,
         persistent: persistent,
         snapshot_strategy: snapshot_strategy,
         deactivate_strategy: deactivate_strategy,
         state: ActorState.new()
       )}
    end)
  end
end
