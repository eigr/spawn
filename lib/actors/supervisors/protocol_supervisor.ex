defmodule Actors.Supervisors.ProtocolSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Actors.Config.Vapor, as: Config

  @default_finch_pool_count System.schedulers_online()
  @default_finch_pool_max_idle_timeout 1_000
  @default_finch_pool_size 10

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def child_spec(config) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [config]}
    }
  end

  @impl true
  def init(config) do
    _actors_config = Config.load(Actors)
    Protobuf.load_extensions()

    children = [
      {Registry, keys: :unique, name: Actors.NodeRegistry},
      http_client_adapter(config)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp http_client_adapter(config) do
    case config.proxy_http_client_adapter do
      "finch" ->
        build_finch_http_client_adapter(config)

      adapter ->
        raise ArgumentError, "Unknown Proxy HTTP Client Adapter #{inspect(adapter)}"
    end
  end

  defp build_finch_http_client_adapter(_config) do
    {
      Finch,
      name: SpawnHTTPClient,
      pools: %{
        :default => [
          size: @default_finch_pool_size,
          count: @default_finch_pool_count,
          pool_max_idle_time: @default_finch_pool_max_idle_timeout
        ]
      }
    }
  end
end
