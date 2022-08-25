defmodule Proxy.Router do
  use Plug.Router

  plug(Plug.Logger)

  plug(MetricsEndpoint.Exporter)
  plug(MetricsEndpoint.PrometheusPipeline)

  plug(:match)
  plug(Plug.Parsers, parsers: [:json, Proxy.Parsers.Protobuf], json_decoder: Jason)
  plug(:dispatch)

  forward("/api/v1", to: Proxy.Routes.API)

  forward("/health", to: Proxy.Routes.Health)

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
