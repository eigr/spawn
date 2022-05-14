defmodule Eigr.Functions.Protocol.Actors.ActorEntity.Supervisor do
  use Horde.DynamicSupervisor

  alias Eigr.Functions.Protocol.Actors.Actor

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [%{}]}
    }
  end

  def start_link(_) do
    Horde.DynamicSupervisor.start_link(
      __MODULE__,
      [
        shutdown: 120_000,
        strategy: :one_for_one,
        members: :auto,
        process_redistribution: :passive,
        delta_crdt_options: [{:sync_interval, 3000}]
      ],
      name: __MODULE__
    )
  end

  @impl true
  def init(args), do: Horde.DynamicSupervisor.init(args)

  @spec add_actor_to_supervisor(Eigr.Functions.Protocol.Actors.Actor.t()) :: {:ok, any}
  @doc """
  Adds a Actor to the dynamic supervisor.
  """
  def add_actor_to_supervisor(%Actor{} = actor) do
    child_spec = %{
      id: Eigr.Functions.Protocol.Actors.ActorEntity,
      start: {Eigr.Functions.Protocol.Actors.ActorEntity, :start_link, [actor]},
      restart: :transient
    }

    case Horde.DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} -> {:ok, pid}
    end
  end
end
