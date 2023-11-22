defmodule Spawn.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config

  @shutdown_timeout_ms 330_000

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts,
      name: String.to_atom("#{String.capitalize(Config.get(:app_name))}.Cluster"),
      shutdown: @shutdown_timeout_ms
    )
  end

  def child_spec(opts) do
    id = String.to_atom("#{String.capitalize(Config.get(:app_name))}.Cluster")

    %{
      id: id,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def init(opts) do
    children =
      [
        cluster_supervisor(opts),
        {Spawn.Cache.LookupCache, []},
        Spawn.Cluster.StateHandoff.ManagerSupervisor.child_spec(opts),
        Spawn.Cluster.Node.Registry.child_spec()
      ]
      |> maybe_start_internal_nats(opts)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_start_internal_nats(children, opts) do
    case Config.get(:use_internal_nats) do
      "false" ->
        children

      _ ->
        Logger.debug("Starting Spawn using Nats control protocol")

        (children ++
           [
             Spawn.Cluster.Node.ConnectionSupervisor.child_spec(opts),
             Spawn.Cluster.Node.ServerSupervisor.child_spec(opts)
           ])
        |> List.flatten()
    end
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
         [name: String.to_atom("#{String.capitalize(Config.get(:app_name))}.${__MODULE__}")]
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
        strategy: Elixir.Cluster.Strategy.Kubernetes.DNS,
        config: [
          service: Config.get(:proxy_headless_service),
          application_name: "spawn",
          polling_interval: Config.get(:proxy_cluster_polling_interval)
        ]
      ]
    ]
end
