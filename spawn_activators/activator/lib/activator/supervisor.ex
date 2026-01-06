defmodule Activator.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger
  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

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
      supervisor_process_logger(__MODULE__),
      ConnectionSupervisor.child_spec(opts)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
