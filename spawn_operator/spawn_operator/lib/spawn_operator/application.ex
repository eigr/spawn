defmodule SpawnOperator.Application do
  @moduledoc false
  use Application

  require Logger

  @port 9090

  @impl true
  def start(_type, env: env) do
    Logger.info("Starting Eigr Spawn Operator Controller...")

    children = [
      {SpawnOperator.Controller.Supervisor,
       conn: SpawnOperator.K8sConn.get(env),
       watch_namespace: :all,
       enable_leader_election: true
       },
      {Bandit, plug: SpawnOperator.Router, scheme: :http, port: @port}
    ]

    opts = [strategy: :one_for_one, name: SpawnOperator.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
