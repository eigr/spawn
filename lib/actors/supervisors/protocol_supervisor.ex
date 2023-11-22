defmodule Actors.Supervisors.ProtocolSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def init(_opts) do
    Protobuf.load_extensions()

    children = [
      {Registry, keys: :unique, name: Actors.NodeRegistry},
      http_client_adapter()
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp http_client_adapter() do
    case Config.get(:proxy_http_client_adapter) do
      "finch" ->
        build_finch_http_client_adapter()

      adapter ->
        raise ArgumentError, "Unknown Proxy HTTP Client Adapter #{inspect(adapter)}"
    end
  end

  defp build_finch_http_client_adapter() do
    pool_schedulers = Config.get(:proxy_http_client_adapter_pool_schedulers)
    pool_max_idle_time = Config.get(:proxy_http_client_adapter_pool_max_idle_timeout)
    size = Config.get(:proxy_http_client_adapter_pool_size)

    {
      Finch,
      name: SpawnHTTPClient,
      pools: %{
        :default => [
          count: pool_schedulers,
          pool_max_idle_time: pool_max_idle_time,
          size: size
        ]
      }
    }
  end
end
