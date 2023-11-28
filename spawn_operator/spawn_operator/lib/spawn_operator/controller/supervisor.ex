defmodule SpawnOperator.Controller.Supervisor do
  @moduledoc false
  use Supervisor
  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  @impl true
  def init(opts) do
    children = [
      supervisor_process_logger(__MODULE__),
      {SpawnOperator.Operator, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
end
