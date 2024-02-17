defmodule Sidecar.Grpc.Reflection.Service do
  @moduledoc """
  This module implement gRPC Reflection
  """
  @moduledoc since: "1.2.1"
  use GRPC.Server, service: Grpc.Reflection.V1alpha.ServerReflection.Service

  require Logger
  alias GRPC.Server
  alias Proxy.Grpc.Reflection, as: ReflectionServer
  alias Grpc.Reflection.V1alpha.{ServerReflectionRequest, ServerReflectionResponse, ErrorResponse}

  @spec server_reflection_info(ServerReflectionRequest.t(), GRPC.Server.Stream.t()) ::
          ServerReflectionResponse.t()
  def server_reflection_info(request, stream) do
    Enum.each(request, fn message ->
      Logger.debug("Received reflection request: #{inspect(message)}")

      response =
        case message.message_request do
          {:list_services, _} ->
            ReflectionServer.list_services()

          {:file_containing_symbol, _} ->
            symbol = elem(message.message_request, 1)
            ReflectionServer.find_by_symbol(symbol)

          {:file_by_filename, _} ->
            filename = elem(message.message_request, 1)
            ReflectionServer.find_by_filename(filename)

          _ ->
            Logger.warn("This Reflection Operation is not supported")

            ServerReflectionResponse.new(
              message_response:
                {:error_response,
                 ErrorResponse.new(error_code: 13, error_message: "Operation not supported")}
            )
        end

      Server.send_reply(stream, response)
    end)
  end
end
