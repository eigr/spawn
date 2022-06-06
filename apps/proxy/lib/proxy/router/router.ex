defmodule Proxy.Router do
  use Plug.Router

  plug(Plug.Logger)

  plug(Proxy.Metrics.Exporter)
  plug(Proxy.Metrics.PrometheusPipeline)

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  forward("/api/v1", to: Proxy.Routes.API)

  forward("/health", to: Proxy.Routes.Health)

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
