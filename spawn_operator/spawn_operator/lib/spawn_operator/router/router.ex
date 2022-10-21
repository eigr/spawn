defmodule SpawnOperator.Router do
  use Plug.Router

  plug(Plug.Logger)

  # plug(MetricsEndpoint.Exporter)
  # plug(MetricsEndpoint.PrometheusPipeline)

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  forward("/health", to: SpawnOperator.Routes.Health)

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
