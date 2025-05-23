defmodule Spawn.Cluster.ClusterSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  alias Actors.Config.PersistentTermConfig, as: Config

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts,
      name: String.to_atom("#{String.capitalize(Config.get(:app_name))}.ClusterSupervisor")
    )
  end

  @impl true
  def init(opts) do
    children =
      [
        supervisor_process_logger(__MODULE__),
        cluster_supervisor(opts)
      ]
      |> maybe_add_provisioner(opts)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_add_provisioner(children, opts) do
    # TODO check if is production env
    children ++ [{Spawn.Cluster.ProvisionerPoolSupervisor, opts}]
  end

  defp cluster_supervisor(opts) do
    cluster_strategy = Config.get(:proxy_cluster_strategy)

    topologies =
      case cluster_strategy do
        "epmd" ->
          get_epmd_strategy(opts)

        "gossip" ->
          get_gossip_strategy(opts)

        "kubernetes-dns" ->
          get_k8s_dns_strategy(opts)

        _ ->
          Logger.warning("Invalid Topology")
      end

    if topologies && Code.ensure_compiled(Cluster.Supervisor) do
      Logger.debug("Cluster topology #{inspect(topologies)}")

      {Cluster.Supervisor,
       [
         topologies,
         [name: String.to_atom("#{String.capitalize(Config.get(:app_name))}.Cluster")]
       ]}
    end
  end

  defp get_epmd_strategy(_opts) do
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

  defp get_gossip_strategy(_opts) do
    [
      proxy: [
        strategy: Cluster.Strategy.Gossip,
        config: [
          reuseaddr: Config.get(:proxy_cluster_gossip_reuseaddr_address),
          multicast_addr: Config.get(:proxy_cluster_gossip_multicast_address),
          broadcast_only: Config.get(:proxy_cluster_gossip_broadcast_only)
        ]
      ]
    ]
  end

  defp get_k8s_dns_strategy(_opts),
    do: [
      proxy: [
        strategy: Elixir.Spawn.Cluster.ClusterResolver,
        config: [
          service: Config.get(:proxy_headless_service),
          application_name: Config.get(:actor_system_name),
          polling_interval: Config.get(:proxy_cluster_polling_interval)
        ]
      ]
    ]
end
