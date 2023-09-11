defmodule Proxy.Routes.API do
  @moduledoc """
  Spawn HTTP Endpoints
  """
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

  alias Eigr.Functions.Protocol.Actors.ActorId

  @content_type "application/octet-stream"

  get "/system/:system/actors/:actor_name" do
    Actors.get_state(%ActorId{name: actor_name, system: system})
  end

  post "/system" do
    remote_ip = get_remote_ip(conn)

    with registration_payload <- get_body(conn.body_params, RegistrationRequest),
         {:ok, response} <- Actors.register(registration_payload, remote_ip: remote_ip) do
      send!(conn, 200, encode(RegistrationResponse, response), @content_type)
    else
      _ ->
        status = %RequestStatus{status: :ERROR, message: "Error on create Actors"}
        response = %RegistrationResponse{status: status}
        send!(conn, 500, encode(RegistrationResponse, response), @content_type)
    end
  end

  post "/system/:name/actors/spawn" do
    remote_ip = get_remote_ip(conn)
    query = Plug.Conn.fetch_query_params(conn)
    {revision, _} = Map.get(query.params, "revision", "0") |> Integer.parse()

    with spawn_payload <- get_body(conn.body_params, SpawnRequest),
         {:ok, response} <-
           Actors.spawn_actor(spawn_payload, remote_ip: remote_ip, revision: revision) do
      send!(conn, 200, encode(SpawnResponse, response), @content_type)
    else
      _ ->
        status = %RequestStatus{status: :ERROR, message: "Error on create Actors"}
        response = %SpawnResponse{status: status}
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
      error ->
        do_handle_error(conn, error)
    end
  end

  defp do_handle_error(conn, {:error, :action_not_found, msg}) do
    Logger.error("The target Actor does not have the invoked Action. Details: #{inspect(msg)}")
    status = %RequestStatus{status: :ERROR, message: msg}
    response = %InvocationResponse{status: status}
    send!(conn, 500, encode(InvocationResponse, response), @content_type)
  end

  defp do_handle_error(conn, {:error, msg}) do
    Logger.error("Error during handling request. Error: #{inspect(msg)}")
    status = %RequestStatus{status: :ERROR, message: msg}
    response = %InvocationResponse{status: status}
    send!(conn, 500, encode(InvocationResponse, response), @content_type)
  end

  defp do_handle_error(conn, error) do
    Logger.error("Error during handling request. Error: #{inspect(error)}")

    status = %RequestStatus{
      status: :ERROR,
      message: "Error on invoke Actor. Details: #{inspect(error)}"
    }

    response = %InvocationResponse{status: status}
    send!(conn, 500, encode(InvocationResponse, response), @content_type)
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

    %InvocationResponse{
      system: system,
      actor: actor,
      payload: resp,
      status: %RequestStatus{status: :OK}
    }
  end
end
