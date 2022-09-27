defmodule Proxy.Application do
  @moduledoc false
  use Application

  alias Actors.Config.Vapor, as: Config

  @impl true
  def start(_type, _args) do
    config = Config.load(__MODULE__)

    # MetricsEndpoint.Exporter.setup()
    # MetricsEndpoint.PrometheusPipeline.setup()

    children = [
      {Proxy.Supervisor, config},
      {Bandit, plug: Proxy.Router, scheme: :http, options: get_http_options(config)}
    ]

    opts = [strategy: :one_for_one, name: Proxy.RootSupervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_http_options(config) do
    if config.proxy_uds_enable == "true" do
      get_uds_options(config)
    else
      get_tcp_options(config)
    end
  end

  defp get_uds_options(config) do
    [
      port: 0,
      transport_options: [ip: {:local, config.proxy_sock_addr}]
    ]
  end

  defp get_tcp_options(config) do
    [
      port: config.http_port
    ]
  end
end
