defmodule Spawn.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config,
      name: String.to_atom("#{String.capitalize(config.app_name)}.Cluster")
    )
  end

  def child_spec(config) do
    id = String.to_atom("#{String.capitalize(config.app_name)}.Cluster")

    %{
      id: id,
      start: {__MODULE__, :start_link, [config]}
    }
  end

  @impl true
  def init(config) do
    children =
      [
        cluster_supervisor(config),
        {Spawn.Cache.LookupCache, []},
        Spawn.Cluster.StateHandoff.ManagerSupervisor.child_spec(config),
        Spawn.Cluster.Node.Registry.child_spec()
      ]
      |> maybe_start_internal_nats(config)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_start_internal_nats(children, config) do
    case config.use_internal_nats do
      "false" ->
        children

      _ ->
        Logger.debug("Starting Spawn using Nats control protocol")

        (children ++
           [
             Spawn.Cluster.Node.ConnectionSupervisor.child_spec(config),
             Spawn.Cluster.Node.ServerSupervisor.child_spec(config)
           ])
        |> List.flatten()
    end
  end

  defp cluster_supervisor(config) do
    cluster_strategy = config.proxy_cluster_strategy

    topologies =
      case cluster_strategy do
        "epmd" ->
          get_epmd_strategy(config)

        "gossip" ->
          get_gossip_strategy(config)

        "kubernetes-dns" ->
          get_k8s_dns_strategy(config)

        _ ->
          Logger.warning("Invalid Topology")
      end

    if topologies && Code.ensure_compiled(Cluster.Supervisor) do
      Logger.debug("Cluster topology #{inspect(topologies)}")

      {Cluster.Supervisor,
       [topologies, [name: String.to_atom("#{String.capitalize(config.app_name)}.${__MODULE__}")]]}
    end
  end

  defp get_epmd_strategy(_config) do
    [
      proxy: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: [
            :"spawn_a@127.0.0.1",
            :"spawn_a1@127.0.0.1",
            :"spawn_a2@127.0.0.1",
            :"spawn_a3@127.0.0.1",
            :"spawn_a4@127.0.0.1",
            :"spawn_actors_node@127.0.0.1",
            :"spawn_actors_node1@127.0.0.1"
          ]
        ]
      ]
    ]
  end

  defp get_gossip_strategy(config) do
    [
      proxy: [
        strategy: Cluster.Strategy.Gossip,
        config: [
          reuseaddr: config.proxy_cluster_gossip_reuseaddr_address,
          multicast_addr: config.proxy_cluster_gossip_multicast_address,
          broadcast_only: config.proxy_cluster_gossip_broadcast_only
        ]
      ]
    ]
  end

  defp get_k8s_dns_strategy(config),
    do: [
      proxy: [
        strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
        config: [
          service: config.proxy_headless_service,
          application_name: "spawn",
          polling_interval: config.proxy_cluster_polling_interval
        ]
      ]
    ]
end
