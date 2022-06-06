defmodule Actors.Application do
  @moduledoc false

  use Application
  require Logger

  alias Actors.Config.Vapor, as: Config

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    config = Config.load()

    children = [
      cluster_supervisor(config),
      {Registry, keys: :unique, name: Actors.NodeRegistry},
      Actors.Registry.ActorRegistry.Supervisor,
      Actors.Node.NodeManager.Supervisor,
      Actors.Actor.Registry.child_spec(),
      Actors.Actor.Entity.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Actors.Supervisor]
    Supervisor.start_link(children, opts)
  end

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
      {Cluster.Supervisor, [topologies, [name: Actors.ClusterSupervisor]]}
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
