defmodule Spawn.Cluster.Node.Distributor do
  @moduledoc """
  Defines a distributed registry for all process.
  """
  require Logger

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

  @doc """
  Registers a `Actors` into the local ETS table.
  """
  def register_local(%ActorSystem{name: name, registry: %Registry{actors: actors} = _registry}) do
    :ets.insert(@actor_table, {name, actors})
    Logger.info("Registered actor system with name: #{name}")
    :ok
  end

  @doc """
  Registers a `Actors` into the remote nodess.
  """
  def register_remote(%ActorSystem{name: name, registry: %Registry{actors: actors} = system) do
    nodes = nodes(name)
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
end
