defmodule Spawn.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  alias Actors.Config.PersistentTermConfig, as: Config

  @shutdown_timeout_ms 330_000

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      shutdown: @shutdown_timeout_ms
    }
  end

  @impl true
  def init(opts) do
    children =
      [
        supervisor_process_logger(__MODULE__),
        {Spawn.Cache.LookupCache, []},
        {Spawn.Cluster.ClusterSupervisor, []},
        process_hub()
      ]
      |> maybe_start_internal_nats(opts)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp process_hub() do
    {ProcessHub,
     %ProcessHub{
       hub_id: Config.get(:actor_system_name),
       # Configure the redundancy strategy.
       redundancy_strategy: %ProcessHub.Strategy.Redundancy.Replication{
         replication_factor: 2,
         replication_model: :active_passive,
         redundancy_signal: :none
       },
       # Configure the migration strategy.
       migration_strategy: %ProcessHub.Strategy.Migration.HotSwap{
         retention: 2000,
         handover: true
       },
       # Configure the synchronization strategy.
       synchronization_strategy: %ProcessHub.Strategy.Synchronization.PubSub{
         sync_interval: 10000
       },
       # Configure the partition tolerance strategy.
       partition_tolerance_strategy: %ProcessHub.Strategy.PartitionTolerance.DynamicQuorum{
         quorum_size: 2
       },
       # Configure the distribution strategy.
       distribution_strategy: %ProcessHub.Strategy.Distribution.ConsistentHashing{}
     }}
  end

  defp maybe_start_internal_nats(children, opts) do
    case Config.get(:use_internal_nats) do
      false ->
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
end
