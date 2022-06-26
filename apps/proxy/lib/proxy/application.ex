defmodule Proxy.Application do
  @moduledoc false
  use Application

  alias Actors.Config.Vapor, as: Config

  @impl true
  def start(_type, _args) do
    config = Config.load()
    Proxy.Metrics.Exporter.setup()
    Proxy.Metrics.PrometheusPipeline.setup()

    children = [
      Actors.Supervisor.child_spec(config),
      {Bandit, plug: Proxy.Router, scheme: :http, options: [port: config.http_port]}
    ]

    opts = [strategy: :one_for_one, name: Proxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
