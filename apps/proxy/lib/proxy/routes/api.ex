defmodule Proxy.Routes.API do
  use Proxy.Routes.Base
  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorSystem}

  alias Eigr.Functions.Protocol.{
    InvocationRequest,
    InvocationResponse,
    RegistrationRequest,
    RegistrationResponse,
    RequestStatus,
    Status
  }

  @content_type "application/octet-stream"

  post "/system" do
    Logger.debug("ActorSystem Received registration request")

    with registration_payload <- get_body(conn.body_params, RegistrationRequest),
         {:ok, response} <- Actors.register(registration_payload) do
      send!(conn, 200, RegistrationResponse.encode(response), @content_type)
    else
      _ ->
        status = RequestStatus.new(status: :ERROR, message: "Error on create Actors")
        response = RegistrationResponse.new(status: status)
        send!(conn, 500, RegistrationResponse.encode(response), @content_type)
    end
  end

  post "/system/:name/actors/:actor_name/invoke" do
    Logger.debug(
      "ActorSystem #{inspect(name)} Received Actor invocation request for Actor #{inspect(actor_name)} #{inspect(conn.body_params)}"
    )

    with request <- get_body(conn.body_params, InvocationRequest),
         {:ok, response} <- Actors.invoke(request) do
      send!(conn, 200, InvocationResponse.encode(response.invocation_response), @content_type)
    else
      _ ->
        status = RequestStatus.new(status: :ERROR, message: "Error on invoke Actor")
        response = InvocationResponse.new(status: status)
        send!(conn, 500, InvocationResponse.encode(response), @content_type)
    end
  end

  post "/system/:name/actors/invoke" do
    Logger.debug(
      "ActorSystem #{inspect(name)} Received Actors invocation request #{inspect(conn.body_params)}"
    )

    send!(conn, 200, Actor.encode(Actor.new(name: "Joe")), @content_type)
  end

  defp get_body(%{"_proto" => body}, type), do: type.decode(body)
  defp get_body(body, _type), do: body
end
