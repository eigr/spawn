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
    children =
      [
        Spawn.StateHandoff.Broker.child_spec(timeout: config.state_handoff_manager_call_timeout)
      ] ++ build_workers_tree(config)

    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: config.state_handoff_max_restarts,
      max_seconds: config.state_handoff_max_seconds
    )
  end

  defp build_workers_tree(config) do
    pool_size = config.state_handoff_manager_pool_size

    Enum.map(1..pool_size, fn id ->
      Spawn.Cluster.StateHandoff.Manager.child_spec(:"state_handoff_manager_#{id}", config)
    end)
  end
end
