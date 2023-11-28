defmodule ActivatorRabbitmq.Supervisor do
  use Supervisor

  import Activator, only: [get_http_port: 1]
  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  @impl true
  def init(opts) do
    children = [
      supervisor_process_logger(__MODULE__),
      Activator.Supervisor.child_spec(opts),
      {Bandit, plug: ActivatorRabbitMQ.Router, scheme: :http, port: get_http_port()},
      ActivatorRabbitmq.Sources.SourceSupervisor.child_spec(opts)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(opts) do
    Supervisor.start_link(
      __MODULE__,
      opts,
      shutdown: 120_000,
      strategy: :one_for_one
    )
  end
end
