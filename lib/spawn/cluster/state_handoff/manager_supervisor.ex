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
        Spawn.StateHandoff.Broker.child_spec(
          timeout: config.state_handoff_manager_call_timeout,
          min: config.state_handoff_manager_call_pool_min,
          max: config.state_handoff_manager_call_pool_max
        )
      ] ++ build_workers_tree(config)

    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: config.state_handoff_max_restarts,
      max_seconds: config.state_handoff_max_seconds
    )
  end

  defp build_workers_tree(config) do
    pool_size =
      if config.state_handoff_manager_pool_size <= 0 do
        System.schedulers_online() * 2
      else
        config.state_handoff_manager_pool_size
      end

    Enum.map(1..pool_size, fn id ->
      Spawn.Cluster.StateHandoff.Manager.child_spec(:"state_handoff_manager_#{id}", config)
    end)
  end
end
