defmodule Spawn.Application do
  @moduledoc false

  use Application
  require Logger

  alias Spawn.Config.Vapor, as: Config

  alias Spawn.Metrics.{
    Exporter,
    PrometheusInstrumenter,
    PrometheusPipeline
  }

  @grpc_opts [
    idle_timeout: :infinity,
    initial_connection_window_size: 2_147_483_647,
    initial_stream_window_size: 2_147_483_647,
    max_connection_window_size: 2_147_483_647,
    max_connection_buffer_size: 1024 * 1024 * 1024,
    max_stream_window_size: 2_147_483_647,
    max_stream_buffer_size: 1024 * 1024 * 1024,
    max_frame_size_received: 16_777_215,
    max_frame_size_sent: :infinity,
    max_received_frame_rate: {999_000_000, 100},
    max_reset_stream_rate: {999_000_000, 100}
  ]

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    config = Config.load()

    Exporter.setup()
    PrometheusPipeline.setup()
    # PrometheusInstrumenter.setup()

    children = [
      http_server(config),
      cluster_supervisor(config),
      {Registry, keys: :unique, name: Spawn.NodeRegistry},
      Spawn.Registry.ActorRegistry.Supervisor,
      Spawn.Proxy.NodeManager.Supervisor,
      Spawn.Actor.Registry.child_spec(),
      Eigr.Functions.Protocol.Actors.ActorEntity.Supervisor
      # grpc_server(config)
    ]

    opts = [strategy: :one_for_one, name: Spawn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp grpc_server(config) do
    %{
      id: GRPC.Server.Supervisor,
      start:
        {GRPC.Server.Supervisor, :start_link,
         [{Spawn.Proxy.Endpoint, config.grpc_port, @grpc_opts}]}
    }
  end

  defp http_server(config) do
    port = get_http_port(config)
    options = [port: port]

    {Bandit, plug: Spawn.HTTP.Router, scheme: :http, options: options}
  end

  defp get_http_port(config), do: config.http_port

  defp cluster_supervisor(config) do
    cluster_strategy = config.proxy_cluster_strategy

    topologies =
      case cluster_strategy do
        "gossip" ->
          get_gossip_strategy()

        "kubernetes-dns" ->
          get_dns_strategy(config)

        _ ->
          Logger.warn("Invalid Topology")
      end

    if topologies && Code.ensure_compiled(Cluster.Supervisor) do
      Logger.info("Cluster Strategy #{cluster_strategy}")

      Logger.debug("Cluster topology #{inspect(topologies)}")
      {Cluster.Supervisor, [topologies, [name: Spawn.ClusterSupervisor]]}
    end
  end

  defp get_gossip_strategy(),
    do: [
      proxy: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

  defp get_dns_strategy(config),
    do: [
      proxy: [
        strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
        config: [
          service: config.proxy_headless_service,
          application_name: config.proxy_app_name,
          polling_interval: config.proxy_cluster_poling_interval
        ]
      ]
    ]
end
