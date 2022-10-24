defmodule Spawn.Cluster.StateHandoff.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  def start_link(state \\ []) do
    Supervisor.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [Spawn.Cluster.StateHandoff]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
