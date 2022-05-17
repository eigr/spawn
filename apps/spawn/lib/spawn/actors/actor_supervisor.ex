defmodule Eigr.Functions.Protocol.Actors.ActorEntity.Supervisor do
  use DynamicSupervisor

  alias Eigr.Functions.Protocol.Actors.Actor

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
  @spec lookup_or_create_actor(Eigr.Functions.Protocol.Actors.Actor.t()) :: {:ok, any}
  def lookup_or_create_actor(%Actor{} = actor) do
    child_spec = %{
      id: Eigr.Functions.Protocol.Actors.ActorEntity,
      start: {Eigr.Functions.Protocol.Actors.ActorEntity, :start_link, [actor]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} -> {:ok, pid}
    end
  end
end
