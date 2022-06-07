defmodule Proxy.Routes.API do
  use Proxy.Routes.Base
  require Logger

  alias Eigr.Functions.Protocol.Actors.Actor
  alias Eigr.Functions.Protocol.{RegistrationRequest, RegistrationResponse, RequestStatus, Status}

  @content_type "application/octet-stream"

  post "/system" do
    Logger.debug("ActorSystem Received registration request")
    registration_payload = get_body(conn.body_params, RegistrationRequest)

    with {:ok, response} <- Actors.register(registration_payload) do
      send!(conn, 200, RegistrationResponse.encode(response), @content_type)
    else
      _ ->
        status = RequestStatus.new(status: :ERROR, message: "Error on create Actors")
        response = RegistrationResponse.new(status: status)
        send!(conn, 500, RegistrationResponse.encode(response), @content_type)
    end
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

    body = get_body(conn.body_params, Actor)

    send!(conn, 200, Actor.encode(body), @content_type)
  end

  defp get_body(%{"_proto" => body}, type), do: type.decode(body)
  defp get_body(body, _type), do: body
end
