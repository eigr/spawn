defmodule Spawn.Cluster.StateHandoff.ManagerSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  def start_link(state \\ []) do
    Supervisor.start_link(__MODULE__, state, name: __MODULE__)
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
      Spawn.Cluster.StateHandoff.Manager.child_spec(:state_handoff_manager, config)
    ]

    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: config.state_handoff_max_restarts,
      max_seconds: config.state_handoff_max_seconds
    )
  end
end
