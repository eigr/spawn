defmodule Activator.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Spawn.Cluster.Node.ConnectionSupervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def init(opts) do
    children = [
      ConnectionSupervisor.child_spec(opts)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
