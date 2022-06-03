defmodule Spawn.HTTP.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  plug(Plug.Logger)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)

  #plug(Spawn.Metrics.Exporter)
  #plug(Spawn.Metrics.PrometheusPipeline)

  get "/health" do
    send_resp(conn, 200, "up!")
  end
end
