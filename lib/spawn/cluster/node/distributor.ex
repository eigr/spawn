defmodule Spawn.Cluster.Node.Distributor do
  @moduledoc """
  Defines a distributed registry for all process.
  """
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config

  alias ProcessHub.Service.ProcessRegistry

  alias Eigr.Functions.Protocol.Actors.Actor
  alias Eigr.Functions.Protocol.Actors.ActorId
  alias Eigr.Functions.Protocol.Actors.ActorSystem
  alias Eigr.Functions.Protocol.Actors.Registry

  @actor_table :actor_registry

  def init() do
    :ets.new(@actor_table, [:named_table, :set, :public])
  end

  def nodes(system), do: ProcessHub.nodes(system)

  def child_specs() do
    [
      registry_actors_distributor_process_hub(),
      init_registry_process(),
      normal_actors_distributor_process_hub(),
      pooled_actors_distributor_process_hub()
    ]
  end

  @doc """
  Registers a `Actors` in a register.
  """
  def register(%ActorSystem{name: name, registry: %Registry{actors: actors}} = system) do
    nodes = nodes("registry_#{name}")
    {res, failed_nodes} = :rpc.multicall(nodes, __MODULE__, :register_local, [system])
    :ets.insert(@actor_table, {name, actors})
    Logger.info("Registered actor system with name: #{name}")
    :ok
  end

  @doc """
  Searches for an actor by system name and actor_id on a local ETS table.
  """
  def find_actor(system_name, %ActorId{} = actor_id) do
    case :ets.lookup(@actor_table, system_name) do
      [] ->
        {:error, :not_found}

      [{^system_name, actors}] ->
        case Enum.find(actors, fn %Actor{id: %ActorId{name: name} = _id} ->
               name == actor_id.name
             end) do
          nil ->
            {:error, :actor_not_found}

          actor ->
            {:ok, actor}
        end
    end
  end

  @doc """
  Get Process if this is alive.
  """
  def lookup(system, actor_name) do
    case ProcessRegistry.lookup(system, actor_name) do
      nil ->
        :not_found

      {%{id: ^actor_name, start: {_module, _fun, _args}}, lookups} ->
        pid =
          lookups
          |> Enum.map(fn {_node, pid} -> pid end)
          |> List.first()

        {:ok, pid}

      error ->
        {:error, error}
    end
  end

  @doc """
  Check if Process is alive.
  """
  def is_alive?(_mod, _actor_name) do
  end

  @doc """
  List all alive PIDs from given registry module.
  """
  @spec list_actor_pids(module()) :: list(pid())
  def list_actor_pids(_mod) do
  end

  defp init_registry_process() do
    %{
      id: :initializer_registry_process,
      start:
        {Task, :start,
         [
           fn ->
             Process.flag(:trap_exit, true)

             ProcessHub.start_children(
               "registry_#{Config.get(:actor_system_name)}",
               [
                 %{
                   id: Spawn.Cluster.Node.GlobalRegistry,
                   start: {Spawn.Cluster.Node.GlobalRegistry, :start_link, [%{}]}
                 }
               ],
               child_mapping: %{
                 self: [Node.self()]
               }
             )

             receive do
               {:EXIT, _pid, reason} ->
                 Logger.info(
                   "[SUPERVISOR] Initializer Registry Process: #{inspect(self())} is successfully down with reason #{inspect(reason)}"
                 )

                 :ok
             end
           end
         ]}
    }
  end

  defp registry_actors_distributor_process_hub() do
    {ProcessHub,
     %ProcessHub{
       hub_id: "registry_#{Config.get(:actor_system_name)}",
       redundancy_strategy: %ProcessHub.Strategy.Redundancy.Replication{
         # TODO get from config
         replication_factor: 2,
         replication_model: :active_active,
         redundancy_signal: :none
       },
       synchronization_strategy: %ProcessHub.Strategy.Synchronization.PubSub{
         # TODO get from config
         sync_interval: 10000
       },
       distribution_strategy: %ProcessHub.Strategy.Distribution.Guided{}
     }}
  end

  defp normal_actors_distributor_process_hub() do
    {ProcessHub,
     %ProcessHub{
       hub_id: Config.get(:actor_system_name),
       redundancy_strategy: %ProcessHub.Strategy.Redundancy.Replication{
         # TODO get from config
         replication_factor: 2,
         replication_model: :active_passive,
         redundancy_signal: :none
       },
       migration_strategy: %ProcessHub.Strategy.Migration.HotSwap{
         # TODO get from config
         retention: 2000,
         handover: true
       },
       synchronization_strategy: %ProcessHub.Strategy.Synchronization.Gossip{
         # TODO get from config
         sync_interval: 10000,
         # TODO get from config
         recipients: 2
       },
       partition_tolerance_strategy: %ProcessHub.Strategy.PartitionTolerance.DynamicQuorum{
         # TODO get from config
         quorum_size: 2
       },
       distribution_strategy: %ProcessHub.Strategy.Distribution.Guided{}
     }}
  end

  defp pooled_actors_distributor_process_hub() do
    {ProcessHub,
     %ProcessHub{
       hub_id: "pooled_#{Config.get(:actor_system_name)}",
       redundancy_strategy: %ProcessHub.Strategy.Redundancy.Replication{
         replication_model: :active_active,
         redundancy_signal: :none
       },
       synchronization_strategy: %ProcessHub.Strategy.Synchronization.PubSub{
         sync_interval: 10000
       },
       partition_tolerance_strategy: %ProcessHub.Strategy.PartitionTolerance.DynamicQuorum{
         quorum_size: 2
       },
       distribution_strategy: %ProcessHub.Strategy.Distribution.Guided{}
     }}
  end
end
