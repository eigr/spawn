defmodule ActivatorRabbitMQ.Application do
  @moduledoc false

  use Application

  @port 9091

  @impl true
  def start(_type, _args) do
    MetricsEndpoint.Exporter.setup()
    MetricsEndpoint.PrometheusPipeline.setup()

    children = [
      {Bandit, plug: ActivatorRabbitMQ.Router, scheme: :http, options: [port: @port]}
    ]

    opts = [strategy: :one_for_one, name: ActivatorRabbitMQ.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
