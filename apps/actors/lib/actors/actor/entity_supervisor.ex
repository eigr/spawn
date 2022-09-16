defmodule Actors.Actor.Entity.Supervisor do
  use DynamicSupervisor

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorSystem}
  alias Actors.Actor.Entity.EntityState

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [%{}]}
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
  @spec lookup_or_create_actor(ActorSystem.t(), Actor.t()) :: {:ok, any}
  def lookup_or_create_actor(%ActorSystem{name: actor_system} = system, %Actor{} = actor) do
    entity_state = %EntityState{system: actor_system, actor: actor}

    child_spec = %{
      id: Actors.Actor.Entity,
      start: {Actors.Actor.Entity, :start_link, [entity_state]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} -> {:ok, pid}
    end
  end
end
