defmodule ActivatorRabbitmq.Supervisor do
  use Supervisor

  import Activator, only: [get_http_port: 1]

  @impl true
  def init(config) do
    children = [
      {Bandit,
       plug: ActivatorRabbitMQ.Router, scheme: :http, options: [port: get_http_port(config)]},
      {Sidecar.Supervisor, config},
      ActivatorRabbitmq.Sources.SourceSupervisor.child_spec()
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(config) do
    Supervisor.start_link(
      __MODULE__,
      config,
      shutdown: 120_000,
      strategy: :one_for_one
    )
  end
end
