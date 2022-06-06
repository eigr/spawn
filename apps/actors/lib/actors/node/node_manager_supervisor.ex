defmodule Actors.Node.NodeManager.Supervisor do
  use DynamicSupervisor

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
  Adds a Connection Manager to the dynamic supervisor.
  """
  def create_connection_manager(state) do
    child_spec = %{
      id: Actors.Node.NodeManager,
      start: {Actors.Node.NodeManager, :start_link, [state]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} -> {:ok, pid}
    end
  end
end
