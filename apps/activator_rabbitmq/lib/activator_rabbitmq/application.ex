defmodule ActivatorRabbitMQ.Application do
  @moduledoc false

  use Application
  require Logger

  alias Actors.Config.Vapor, as: Config

  import Activator, only: [get_http_port: 1]

  @impl true
  def start(_type, _args) do
    config = Config.load(__MODULE__)

    MetricsEndpoint.Exporter.setup()
    MetricsEndpoint.PrometheusPipeline.setup()

    children =
      [
        Spawn.Cluster.Supervisor.child_spec(config),
        {Bandit,
         plug: ActivatorRabbitMQ.Router, scheme: :http, options: [port: get_http_port(config)]}
      ] ++ if Mix.env() == :test, do: [], else: [Actors.Actor.Registry.child_spec()]

    opts = [strategy: :one_for_one, name: ActivatorRabbitMQ.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
