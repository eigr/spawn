defmodule SpawnSdk.System.SpawnSystem do
  @moduledoc """
  `SpawnSystem`
  """
  @behaviour SpawnSdk.System
  require Logger

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
    ProxyInfo,
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

  @impl SpawnSdk.System
  def register(system, actors) do
    case Actors.register(build_registration_req(system, actors)) do
      {:ok, %RegistrationResponse{proxy_info: proxy_info, status: status}} ->
        Logger.debug(
          "Actors registration succed. Proxy info: #{inspect(proxy_info)}. Status: #{inspect(status)}"
        )

        :ok

      error ->
        {:error, "Actors registration failed. Error #{inspect(error)}"}
    end
  end

  @impl SpawnSdk.System
  def invoke(actor, command, payload, options) do
    async = Keyword.get(options, :async, false)
    input_type = Keyword.fetch!(options, :input_type)
    output_type = Keyword.fetch!(options, :output_type)
    {:ok, nil}
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
      name = actor.__name__
      persistent = actor.__persistent__
      snapshot_timeout = actor.__snapshot_timeout__
      deactivate_timeout = actor.__deactivate_timeout__

      snapshot_strategy =
        ActorSnapshotStrategy.new(
          strategy: {:timout, TimeoutStrategy.new(timeout: snapshot_timeout)}
        )

      deactivate_strategy =
        ActorDeactivateStrategy.new(
          strategy: {:timout, TimeoutStrategy.new(timeout: snapshot_timeout)}
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
