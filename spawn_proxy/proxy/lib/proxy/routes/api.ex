defmodule Proxy.Routes.API do
  use Proxy.Routes.Base
  require Logger

  alias Eigr.Functions.Protocol.{
    ActorInvocationResponse,
    InvocationRequest,
    InvocationResponse,
    RegistrationRequest,
    RegistrationResponse,
    RequestStatus,
    SpawnRequest,
    SpawnResponse
  }

  @content_type "application/octet-stream"

  get "/system/:name/actors/:actor_name" do
    Actors.get_state(name, actor_name)
  end

  post "/system" do
    remote_ip = get_remote_ip(conn)

    with registration_payload <- get_body(conn.body_params, RegistrationRequest),
         {:ok, response} <- Actors.register(registration_payload, remote_ip: remote_ip) do
      send!(conn, 200, encode(RegistrationResponse, response), @content_type)
    else
      _ ->
        status = RequestStatus.new(status: :ERROR, message: "Error on create Actors")
        response = RegistrationResponse.new(status: status)
        send!(conn, 500, encode(RegistrationResponse, response), @content_type)
    end
  end

  post "/system/:name/actors/spawn" do
    remote_ip = get_remote_ip(conn)

    with spawn_payload <- get_body(conn.body_params, SpawnRequest),
         {:ok, response} <- Actors.spawn_actor(spawn_payload, remote_ip: remote_ip) do
      send!(conn, 200, encode(SpawnResponse, response), @content_type)
    else
      _ ->
        status = RequestStatus.new(status: :ERROR, message: "Error on create Actors")
        response = SpawnResponse.new(status: status)
        send!(conn, 500, encode(SpawnResponse, response), @content_type)
    end
  end

  post "/system/:name/actors/:actor_name/invoke" do
    remote_ip = get_remote_ip(conn)

    with %InvocationRequest{system: system, actor: actor} = request <-
           get_body(conn.body_params, InvocationRequest),
         {:ok, response} <- Actors.invoke(request, remote_ip: remote_ip) do
      resp = build_response(system, actor, response)

      send!(conn, 200, encode(InvocationResponse, resp), @content_type)
    else
      _ ->
        status = RequestStatus.new(status: :ERROR, message: "Error on invoke Actor")
        response = InvocationResponse.new(status: status)
        send!(conn, 500, encode(InvocationResponse, response), @content_type)
    end
  end

  defp get_body(%{"_proto" => body}, type), do: type.decode(body)
  defp get_body(body, _type), do: body

  defp encode(module, payload), do: module.encode(payload)

  defp get_remote_ip(conn), do: to_string(:inet_parse.ntoa(conn.remote_ip))

  defp build_response(system, actor, response) do
    # This case is necessary because the plug has a strange behavior and seems to execute the handler twice however,
    # the second time the payload is incorrect. Open to future investigations.
    resp =
      case response do
        %ActorInvocationResponse{payload: {:value, %Google.Protobuf.Any{} = value}} ->
          {:value, value}

        %ActorInvocationResponse{payload: %Google.Protobuf.Any{} = response} ->
          {:value, response}

        %ActorInvocationResponse{payload: response} ->
          response

        :async ->
          nil

        _ ->
          response
      end

    InvocationResponse.new(
      system: system,
      actor: actor,
      payload: resp,
      status: RequestStatus.new(status: :OK)
    )
  end
end
