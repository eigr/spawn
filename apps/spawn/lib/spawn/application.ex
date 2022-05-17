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

  @cowboy_options [compress: true]

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    config = Config.load()
    Exporter.setup()
    PrometheusPipeline.setup()
    PrometheusInstrumenter.setup()

    children = [
      cluster_supervisor(config),
      {Registry, keys: :unique, name: Spawn.NodeRegistry},
      Spawn.Registry.ActorRegistry.Supervisor,
      Spawn.Proxy.NodeManager.Supervisor,
      Spawn.Actor.Registry.child_spec(),
      Eigr.Functions.Protocol.Actors.ActorEntity.Supervisor,
      http_server(config),
      grpc_server(config)
    ]

    opts = [strategy: :one_for_one, name: Spawn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp grpc_server(config) do
    %{
      id: GRPC.Server.Supervisor,
      start: {GRPC.Server.Supervisor, :start_link, [{Spawn.Proxy.Endpoint, config.grpc_port}]}
    }
  end

  defp http_server(config) do
    port = get_http_port(config)
    options = @cowboy_options ++ [port: port]

    {Plug.Cowboy, plug: Spawn.HTTP.Router, scheme: :http, options: options}
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
