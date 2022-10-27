defmodule SpawnOperator.Controller.Supervisor do
  use Supervisor

  @impl true
  def init(opts) do
    children = [
      {SpawnOperator.Operator, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
end
