defmodule Spawn.Cluster.StateHandoffManager.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  @state_handoff_call_timeout 60_000

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
    pool_size = 20

    workers =
      Enum.map(1..pool_size, fn id ->
        Spawn.Cluster.StateHandoffManager.child_spec(:"state_handoff_#{id}", config)
      end)

    children =
      [
        Spawn.StateHandoff.Broker.child_spec(timeout: @state_handoff_call_timeout)
      ] ++ workers

    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: config.state_handoff_max_restarts,
      max_seconds: config.state_handoff_max_seconds
    )
  end
end
