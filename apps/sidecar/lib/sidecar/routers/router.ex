defmodule Sidecar.Routers.Router do
  use Plug.Router

  plug(Sidecar.Metrics.Exporter)
  plug(Sidecar.Metrics.PrometheusPipeline)

  plug(Plug.Logger)

  plug(:match)
  plug(:dispatch)

  get "/health" do
    send_resp(conn, 200, "up!")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
