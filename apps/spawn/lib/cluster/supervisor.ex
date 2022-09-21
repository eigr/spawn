defmodule Spawn.Cluster.Supervisor do
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
        cluster_supervisor(config)
      ] ++
        if Mix.env() == :test,
          do: [],
          else: [Spawn.Cluster.Node.Registry.child_spec()]

    Supervisor.init(children, strategy: :one_for_one)
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
          Logger.warning("Invalid Topology")
      end

    if topologies && Code.ensure_compiled(Cluster.Supervisor) do
      Logger.debug("Cluster topology #{inspect(topologies)}")

      {Cluster.Supervisor,
       [topologies, [name: String.to_atom("#{String.capitalize(config.app_name)}.${__MODULE__}")]]}
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
