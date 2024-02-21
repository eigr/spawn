defmodule Sidecar.GRPC.Dispatcher do
  @moduledoc """
  Module for dispatching gRPC messages to Actors.

  This module handles the dispatching of gRPC messages to Actors based on the provided parameters.
  It logs relevant information and raises an error if the service descriptor is not found.

  """
  require Logger

  alias Actors.Registry.ActorRegistry
  alias Actors.Registry.HostActor
  alias Eigr.Functions.Protocol.Actors.Actor
  alias Eigr.Functions.Protocol.Actors.ActorId
  alias Eigr.Functions.Protocol.Actors.ActorSettings

  alias GRPC.Server
  alias Sidecar.GRPC.ServiceResolver, as: ActorResolver

  @doc """
    Dispatches a gRPC message to the specified actor.

    ### Parameters:

    - `request` - A map containing the following parameters:
      - `system: system_name` - The name of the actor system.
      - `actor_name: actor_name` - The name of the actor.
      - `action_name: action_name` - The name of action to call.
      - `input: message` - The input message.
      - `stream: stream` - The stream (optional).
      - `descriptor: descriptor` - The service descriptor.

    ### Example:

    ```elixir
    request = %{
      system: "spawn-system",
      actor_name: "GreeterActor",
      action_name: "SayHello",
      input: %{data: "some_data"},
      stream: %GRPC.Server.Stream{},
      descriptor: %Google.Protobuf.FileDescriptorProto{
        name: "helloworld.proto",
        package: "helloworld"},
        service: [
          %Google.Protobuf.ServiceDescriptorProto{
            name: "GreeterActor",
            method: [
              %Google.Protobuf.MethodDescriptorProto{
                name: "SayHello",
                input_type: ".helloworld.HelloRequest",
                output_type: ".helloworld.HelloReply",
              }
            ]
          }
        ]
      }
    }

    Sidecar.GRPC.Dispatcher.dispatch(request)

  """
  def dispatch(
        %{
          system: system_name,
          actor_name: actor_name,
          descriptor: descriptor
        } = _request
      )
      when is_nil(descriptor) do
    Logger.error(
      "Service descriptor not found. Impossible to call Actor #{system_name}:#{actor_name}"
    )

    raise GRPC.RPCError,
      status: GRPC.Status.failed_precondition(),
      message:
        "Service descriptor not found. Impossible to call Actor #{system_name}:#{actor_name}"
  end

  def dispatch(
        %{
          system: system_name,
          actor_name: actor_name,
          action_name: action_name,
          input: message,
          stream: %GRPC.Server.Stream{grpc_type: grpc_type} = stream,
          descriptor: descriptor
        } = request
      ) do
    Logger.debug(
      "Dispatching gRPC message to Actor #{system_name}:#{actor_name}. Params: #{inspect(request)}"
    )

    # TODO
    # Before forwading the request, we must find out through the ServiceResolver module what type of RPC
    # it is (unary, client streaming, server streaming, etc...). This way we will know how to forward
    # the request correctly (synchronously or asynchronously), as well as how to properly handle the GRPC response.
    case grpc_type do
      :client_stream ->
        handle_client_stream(system_name, actor_name, action_name, message, stream, descriptor)

      :server_stream ->
        handle_server_stream(system_name, actor_name, action_name, message, stream, descriptor)

      :bidirectional_stream ->
        handle_bidirectional_stream(
          system_name,
          actor_name,
          action_name,
          message,
          stream,
          descriptor
        )

      _ ->
        handle_unary(system_name, actor_name, action_name, message, stream, descriptor)
    end
  end

  defp handle_unary(system_name, actor_name, action_name, message, stream, descriptor) do
    req =
      build_id(system_name, actor_name, message)
      |> build_request(message)
  end

  defp handle_client_stream(system_name, actor_name, action_name, message, stream, descriptor) do
    req =
      build_id(system_name, actor_name, message)
      |> build_request(message)
  end

  defp handle_server_stream(system_name, actor_name, action_name, message, stream, descriptor) do
    req =
      build_id(system_name, actor_name, message)
      |> build_request(message)
  end

  defp handle_bidirectional_stream(
         system_name,
         actor_name,
         action_name,
         message,
         stream,
         descriptor
       ) do
    req =
      build_id(system_name, actor_name, message)
      |> build_request(message)
  end

  # %Google.Protobuf.DescriptorProto{
  #   name: "HelloRequest",
  #   field: [
  #     %Google.Protobuf.FieldDescriptorProto{
  #       name: "name",
  #       extendee: nil,
  #       number: 1,
  #       label: :LABEL_OPTIONAL,
  #       type: :TYPE_STRING,
  #       type_name: nil,
  #       default_value: nil,
  #       options: %Google.Protobuf.FieldOptions{
  #         ctype: :STRING,
  #         packed: nil,
  #         deprecated: false,
  #         lazy: false,
  #         jstype: :JS_NORMAL,
  #         weak: false,
  #         unverified_lazy: false,
  #         debug_redact: false,
  #         uninterpreted_option: [],
  #         __pb_extensions__: %{
  #           {Eigr.Functions.Protocol.Actors.PbExtension, :actor_id} => true
  #         },
  #         __unknown_fields__: []
  #       },
  #       oneof_index: nil,
  #       json_name: "name",
  #       proto3_optional: nil,
  #       __unknown_fields__: []
  #     }
  #   ],
  #   nested_type: [],
  #   enum_type: [],
  #   extension_range: [],
  #   extension: [],
  #   options: nil,
  #   oneof_decl: [],
  #   reserved_range: [],
  #   reserved_name: [],
  #   __unknown_fields__: []
  # }
  defp build_id(system_name, actor_name, message) do
    actor_id = %ActorId{system: system_name, name: actor_name}
    host_actor = ActorRegistry.lookup(actor_id)

    case host_actor do
      {:ok, %HostActor{actor: %Actor{settings: %ActorSettings{kind: :NAMED}}}} ->
        actor_id

      {:ok, %HostActor{actor: %Actor{settings: %ActorSettings{kind: :UNNAMED}}}} ->
        name =
          Enum.find_value(message.descriptor().field, fn %Google.Protobuf.FieldDescriptorProto{
                                                           name: name,
                                                           options:
                                                             %{__pb_extensions__: ext} = _options
                                                         } ->
            Map.get(ext, {Eigr.Functions.Protocol.Actors.PbExtension, :actor_id}, false) && name
          end)

        id =
          if not is_nil(name) and Map.has_key?(message, name) do
            %ActorId{system: system_name, name: Map.get(message, name), parent: actor_name}
          else
            nil
          end

        id

      _ ->
        nil
    end
  end

  def build_request(actor_id, message) do
  end
end
