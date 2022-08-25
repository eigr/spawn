defmodule ActivatorPubSub.Application do
  @moduledoc false

  use Application

  @port 9091

  @impl true
  def start(_type, _args) do
    MetricsEndpoint.Exporter.setup()
    MetricsEndpoint.PrometheusPipeline.setup()

    children = [
      {Bandit, plug: ActivatorPubSub.Router, scheme: :http, options: [port: @port]}
    ]

    opts = [strategy: :one_for_one, name: ActivatorPubSub.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
