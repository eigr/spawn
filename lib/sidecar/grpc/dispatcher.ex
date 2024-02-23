defmodule Sidecar.GRPC.Dispatcher do
  @moduledoc """
  Module for dispatching gRPC messages to Actors.

  This module handles the dispatching of gRPC messages to Actors based on the provided parameters.
  It logs relevant information and raises an error if the service descriptor is not found.
  """
  require Logger

  alias Actors.Actor.CallerProducer
  alias Actors.Registry.ActorRegistry
  alias Actors.Registry.HostActor

  alias Eigr.Functions.Protocol.Actors.Actor
  alias Eigr.Functions.Protocol.Actors.ActorId
  alias Eigr.Functions.Protocol.Actors.ActorSettings
  alias Eigr.Functions.Protocol.Actors.ActorSystem
  alias Eigr.Functions.Protocol.InvocationRequest

  alias GRPC.Server
  alias GRPC.Server.Stream, as: GRPCStream

  alias Sidecar.GRPC.ServiceResolver, as: ActorResolver

  import Spawn.Utils.AnySerializer, only: [any_pack!: 1]

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
  def dispatch(%{system: system_name, actor_name: actor_name, descriptor: nil} = _request) do
    handle_error(
      "Service descriptor not found. Impossible to call Actor #{system_name}:#{actor_name}",
      GRPC.Status.failed_precondition()
    )
  end

  def dispatch(
        %{
          system: system_name,
          actor_name: actor_name,
          action_name: action_name,
          input: message,
          stream: %GRPCStream{grpc_type: grpc_type} = stream,
          descriptor: _descriptor
        } = request
      ) do
    Logger.debug(
      "Dispatching gRPC message to Actor #{system_name}:#{actor_name}. Params: #{inspect(request)}"
    )

    handle_dispatch(system_name, actor_name, action_name, message, stream, grpc_type)
  end

  defp handle_dispatch(system_name, actor_name, action_name, message, stream, :client_stream),
    do: handle_client_stream(system_name, actor_name, action_name, message, stream)

  defp handle_dispatch(system_name, actor_name, action_name, message, stream, :server_stream),
    do: handle_server_stream(system_name, actor_name, action_name, message, stream)

  defp handle_dispatch(
         system_name,
         actor_name,
         action_name,
         message,
         stream,
         :bidirectional_stream
       ),
       do: handle_bidirectional_stream(system_name, actor_name, action_name, message, stream)

  defp handle_dispatch(system_name, actor_name, action_name, message, stream, _),
    do: handle_unary(system_name, actor_name, action_name, message, stream)

  defp handle_client_stream(system_name, actor_name, action_name, message, stream) do
    Stream.each(message, fn msg ->
      dispatch_async(system_name, actor_name, action_name, msg, stream)
    end)
    |> Stream.run()
  end

  defp handle_server_stream(system_name, actor_name, action_name, message, stream) do
    dispatch_async(system_name, actor_name, action_name, message, stream)
  end

  defp handle_bidirectional_stream(system_name, actor_name, action_name, message, stream) do
    Stream.each(message, fn msg ->
      dispatch_sync(system_name, actor_name, action_name, msg, stream)
    end)
    |> Stream.run()
  end

  defp handle_unary(system_name, actor_name, action_name, message, stream) do
    dispatch_sync(system_name, actor_name, action_name, message, stream)
  end

  defp dispatch_sync(system_name, actor_name, action_name, message, stream) do
    build_actor_id(system_name, actor_name, message)
    |> build_request(system_name, action_name, message, async: false)
    |> invoke_request()
    |> case do
      {:ok, response} ->
        Server.send_reply(stream, response)

      error ->
        log_and_raise_error(
          "Failure during Actor processing. Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )
    end
  end

  defp dispatch_async(system_name, actor_name, action_name, message, stream) do
    build_actor_id(system_name, actor_name, message)
    |> build_request(system_name, action_name, message, async: true)
    |> invoke_request()
    |> case do
      {:ok, :async} ->
        Server.send_reply(stream, %{})

      error ->
        log_and_raise_error(
          "Failure during Actor processing. Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )
    end
  end

  defp build_actor_id(system_name, actor_name, message) do
    {:ok, %HostActor{actor: %Actor{settings: %ActorSettings{} = actor_settings}}} =
      ActorRegistry.lookup(%ActorId{system: system_name, name: actor_name})

    build_actor_id_from_settings(system_name, actor_name, actor_settings, message)
  end

  defp build_actor_id_from_settings(
         system_name,
         actor_name,
         %ActorSettings{kind: :NAMED} = _settings,
         _message
       ) do
    %ActorId{system: system_name, name: actor_name}
  end

  defp build_actor_id_from_settings(
         system_name,
         actor_name,
         %ActorSettings{kind: :UNNAMED} = _settings,
         message
       ) do
    {ctype, name} = find_actor_name_and_ctype(message)
    actor_id_name = get_actor_id_name(ctype, message, name)
    %ActorId{system: system_name, name: actor_id_name, parent: actor_name}
  end

  defp build_actor_id_from_settings(_, _, _, _), do: nil

  defp find_actor_name_and_ctype(message) do
    Enum.find_value(message.descriptor().field, fn %Google.Protobuf.FieldDescriptorProto{
                                                     name: name,
                                                     options: %Google.Protobuf.FieldOptions{
                                                       ctype: ctype,
                                                       __pb_extensions__: ext
                                                     }
                                                   } ->
      Map.get(ext, {Eigr.Functions.Protocol.Actors.PbExtension, :actor_id}, false) &&
        {ctype, name}
    end)
  end

  defp get_actor_id_name(:STRING, message, attribute), do: Map.get(message, attribute)

  defp get_actor_id_name(_ctype, message, attribute),
    do: "#{inspect(Map.get(message, attribute))}"

  defp build_request(actor_id, actor_system, action_name, message, opts) do
    async = Keyword.get(opts, :async, false)

    %InvocationRequest{
      async: async,
      system: %ActorSystem{name: actor_system},
      actor: %Actor{id: actor_id},
      action_name: action_name,
      payload: {:value, any_pack!(message)}
    }
  end

  defp invoke_request(nil), do: {:error, :invalid_payload}
  defp invoke_request(request), do: CallerProducer.invoke(request)

  defp log_and_raise_error(message, status) do
    Logger.error(message)
    raise GRPC.RPCError, status: status, message: message
  end

  defp handle_error(message, status) do
    log_and_raise_error(message, status)
  end
end
