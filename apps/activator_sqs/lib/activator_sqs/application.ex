defmodule ActivatorSQS.Application do
  @moduledoc false

  use Application

  alias Activator.Config.Vapor, as: Config
  import Activator, only: [get_http_port: 1]

  @impl true
  def start(_type, _args) do
    config = Config.load()

    MetricsEndpoint.Exporter.setup()
    MetricsEndpoint.PrometheusPipeline.setup()

    children = [
      {Bandit, plug: ActivatorSQS.Router, scheme: :http, options: [port: get_http_port(config)]}
    ]

    opts = [strategy: :one_for_one, name: ActivatorSQS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
