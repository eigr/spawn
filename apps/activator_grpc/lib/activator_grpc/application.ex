defmodule ActivatorGRPC.Application do
  @moduledoc false

  use Application

  @http_port if Mix.env() == :test, do: 0, else: 9091

  @impl true
  def start(_type, _args) do
    MetricsEndpoint.Exporter.setup()
    MetricsEndpoint.PrometheusPipeline.setup()

    children = [
      {Bandit, plug: ActivatorGRPC.Router, scheme: :http, options: [port: @http_port]}
    ]

    opts = [strategy: :one_for_one, name: ActivatorGRPC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
