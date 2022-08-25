defmodule ActivatorSQS.Application do
  @moduledoc false

  use Application

  @port if Mix.env() == :test, do: 0, else: 9091

  @impl true
  def start(_type, _args) do
    MetricsEndpoint.Exporter.setup()
    MetricsEndpoint.PrometheusPipeline.setup()

    children = [
      {Bandit, plug: ActivatorSQS.Router, scheme: :http, options: [port: @port]}
    ]

    opts = [strategy: :one_for_one, name: ActivatorSQS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
