defmodule Sidecar.Application do
  @moduledoc false

  use Application

  @http_options [port: 9001]

  @impl true
  def start(_type, _args) do
    Sidecar.Metrics.Exporter.setup()
    Sidecar.Metrics.PrometheusPipeline.setup()

    children = [
      {Bandit, plug: Sidecar.Routers.Router, scheme: :http, options: @http_options}
    ]

    opts = [strategy: :one_for_one, name: Sidecar.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
