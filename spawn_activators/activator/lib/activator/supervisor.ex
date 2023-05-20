defmodule Activator.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Spawn.Cluster.Node.ConnectionSupervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def child_spec(config) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [config]}
    }
  end

  @impl true
  def init(config) do
    children = [
      ConnectionSupervisor.child_spec(config)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
