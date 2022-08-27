defmodule ActivatorRabbitMQ.Application do
  @moduledoc false

  use Application

  alias Activator.Config.Vapor, as: ActivatorConfig
  alias Actors.Config.Vapor, as: ActorConfig

  import Activator, only: [get_http_port: 1]

  @impl true
  def start(_type, _args) do
    actor_cfg = ActorConfig.load()
    activator_cfg = ActivatorConfig.load()

    MetricsEndpoint.Exporter.setup()
    MetricsEndpoint.PrometheusPipeline.setup()

    children = [
      # Actors.Supervisor.child_spec(actor_cfg),
      {Bandit,
       plug: ActivatorRabbitMQ.Router,
       scheme: :http,
       options: [port: get_http_port(activator_cfg)]}
    ]

    opts = [strategy: :one_for_one, name: ActivatorRabbitMQ.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
