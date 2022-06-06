defmodule Proxy.Routes.API do
  use Proxy.Routes.Base
  require Logger

  alias Eigr.Functions.Protocol.Actors.Actor

  @content_type "application/octet-stream"

  post "/system" do
    Logger.debug("ActorSystem Received registration request #{inspect(conn.body_params)}")
    send!(conn, 200, Actor.encode(Actor.new(name: "Joe")), @content_type)
  end

  post "/system/:name/actors/invoke" do
    Logger.debug(
      "ActorSystem #{inspect(name)} Received Actors invocation request #{inspect(conn.body_params)}"
    )

    send!(conn, 200, Actor.encode(Actor.new(name: "Joe")), @content_type)
  end

  post "/system/:name/actors/:actor_name/invoke" do
    Logger.debug(
      "ActorSystem #{inspect(name)} Received Actor invocation request for Actor #{inspect(actor_name)} #{inspect(conn.body_params)}"
    )

    decoded_payload = Actor.decode(conn.body_params)

    send!(conn, 200, Actor.encode(decoded_payload), @content_type)
  end
end
