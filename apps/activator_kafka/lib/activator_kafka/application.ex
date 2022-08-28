defmodule ActivatorKafka.Application do
  @moduledoc false

  use Application

  alias Actors.Config.Vapor, as: Config
  import Activator, only: [get_http_port: 1]

  @impl true
  def start(_type, _args) do
    config = Config.load(__MODULE__)

    MetricsEndpoint.Exporter.setup()
    MetricsEndpoint.PrometheusPipeline.setup()

    children = [
      {Bandit, plug: ActivatorKafka.Router, scheme: :http, options: [port: get_http_port(config)]}
    ]

    opts = [strategy: :one_for_one, name: ActivatorKafka.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
