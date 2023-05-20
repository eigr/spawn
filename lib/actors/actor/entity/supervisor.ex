defmodule Actors.Actor.Entity.Supervisor do
  @moduledoc """
  `Entity.Supervisor` is the Supervisor of all Host Actors in the system.
  This in turn is Partitioned using a PartitionSupervisor.
  We use a hash function based on each Actor's child_spec to partition the actors
  so that the entire Supervisor is not overloaded and
  lessening the possibility of cascading failures.
  """
  use DynamicSupervisor
  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorSystem}
  alias Actors.Actor.Entity.EntityState

  @default_number_of_partitions 8

  def child_spec(config) do
    {
      PartitionSupervisor,
      child_spec: DynamicSupervisor,
      name: __MODULE__,
      max_restarts: config.actors_max_restarts,
      max_seconds: config.actors_max_seconds,
      partitions: get_number_of_partitions()
    }
  end

  def start_link(_) do
    DynamicSupervisor.start_link(
      __MODULE__,
      [
        shutdown: 120_000,
        strategy: :one_for_one
      ],
      name: __MODULE__
    )
  end

  @impl true
  def init(args), do: DynamicSupervisor.init(args)

  @doc """
  Adds a Actor to the dynamic supervisor.
  """
  @spec lookup_or_create_actor(ActorSystem.t(), Actor.t(), any()) :: {:ok, any}
  def lookup_or_create_actor(system, actor, opts \\ [])

  def lookup_or_create_actor(system, %Actor{} = actor, opts) when is_nil(system) do
    entity_state = %EntityState{system: nil, actor: actor, opts: opts}

    child_spec = %{
      id: Actors.Actor.Entity,
      start: {Actors.Actor.Entity, :start_link, [entity_state]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(via(child_spec), child_spec) do
      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:ok, pid} ->
        {:ok, pid}

      {:error, {:name_conflict, {{Actors.Actor.Entity, name}, _f}, _registry, pid}} ->
        Logger.warning("Name conflict on start Actor #{name} from PID #{inspect(pid)}.")

        :ignore
    end
  end

  def lookup_or_create_actor(
        %ActorSystem{name: actor_system} = _system,
        %Actor{} = actor,
        opts
      ) do
    entity_state = %EntityState{system: actor_system, actor: actor, opts: opts}

    child_spec = %{
      id: Actors.Actor.Entity,
      start: {Actors.Actor.Entity, :start_link, [entity_state]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(via(child_spec), child_spec) do
      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:ok, pid} ->
        {:ok, pid}

      {:error, {:name_conflict, {{Actors.Actor.Entity, name}, _f}, _registry, pid}} ->
        Logger.warning("Name conflict on start Actor #{name} from PID #{inspect(pid)}.")

        :ignore
    end
  end

  defp get_key(spec), do: :erlang.phash2(Map.drop(spec, [:id]))

  defp via(spec), do: {:via, PartitionSupervisor, {__MODULE__, get_key(spec)}}

  defp get_number_of_partitions() do
    if System.schedulers_online() > 1 do
      System.schedulers_online()
    else
      @default_number_of_partitions
    end
  end
end
