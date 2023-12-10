defmodule Spawn.Cluster.StateHandoff.ManagerSupervisor do
  @moduledoc false
  use Supervisor
  require Logger
  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  alias Actors.Config.PersistentTermConfig, as: Config

  def start_link(state \\ []) do
    Supervisor.start_link(__MODULE__, state, name: __MODULE__)
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
      supervisor_process_logger(__MODULE__),
      Spawn.Cluster.StateHandoff.Manager.child_spec(:state_handoff_manager, opts),
      Spawn.Cluster.StateHandoff.InvocationSchedulerState.child_spec(opts)
    ]

    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: Config.get(:state_handoff_max_restarts),
      max_seconds: Config.get(:state_handoff_max_seconds)
    )
  end
end
