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

  alias Spawn.ActorInvocationResponse
  alias Spawn.Actors.Actor
  alias Spawn.Actors.ActorId
  alias Spawn.Actors.ActorSettings
  alias Spawn.Actors.ActorSystem
  alias Spawn.InvocationRequest

  alias GRPC.Server
  alias GRPC.Server.Stream, as: GRPCStream

  import Spawn.Utils.AnySerializer, only: [any_pack!: 1, unpack_unknown: 1]

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
        } = _request
      ) do
    Logger.info(
      "Dispatching gRPC message to Actor #{system_name}:#{actor_name}. with grpc_type: #{grpc_type}"
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

  defp handle_dispatch(system_name, actor_name, action_name, message, stream, :unary),
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

  defp dispatch_sync(system_name, actor_name, "Readiness", message, stream) do
    with {:actor_id, actor_id} <- {:actor_id, build_actor_id(system_name, actor_name, message)},
         {:response, {:ok, response}} <- {:response, invoke_readiness(actor_id)} do
      server_send_reply(stream, response)
    else
      {:actor_id, {:not_found, _}} ->
        log_and_raise_error(
          :warning,
          "Actor Not Found. The Actor probably does not exist or not implemented or the request params are incorrect!",
          GRPC.Status.not_found()
        )

      {:actor_id, error} ->
        log_and_raise_error(
          :error,
          "Failed to build actor ID for Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )

      {:response, error} ->
        log_and_raise_error(
          :error,
          "Failed to invoke request for Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )
    end
  end

  defp dispatch_sync(system_name, actor_name, "Liveness", message, stream) do
    with {:actor_id, actor_id} <- {:actor_id, build_actor_id(system_name, actor_name, message)},
         {:response, {:ok, response}} <- {:response, invoke_liveness(actor_id)} do
      server_send_reply(stream, response)
    else
      {:actor_id, {:not_found, _}} ->
        log_and_raise_error(
          :warning,
          "Actor Not Found. The Actor probably does not exist or not implemented or the request params are incorrect!",
          GRPC.Status.not_found()
        )

      {:actor_id, error} ->
        log_and_raise_error(
          :error,
          "Failed to build actor ID for Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )

      {:response, error} ->
        log_and_raise_error(
          :error,
          "Failed to invoke request for Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )
    end
  end

  defp dispatch_sync(system_name, actor_name, action_name, message, stream) do
    with {:actor_id, actor_id} <- {:actor_id, build_actor_id(system_name, actor_name, message)},
         {:request, {:ok, request}} <-
           {:request, build_request(actor_id, system_name, action_name, message, async: false)},
         {:response, {:ok, response}} <- {:response, invoke_request(request)} do
      server_send_reply(stream, response)
    else
      {:actor_id, {:not_found, _}} ->
        log_and_raise_error(
          :warning,
          "Actor Not Found. The Actor probably does not exist or not implemented or the request params are incorrect!",
          GRPC.Status.not_found()
        )

      {:actor_id, error} ->
        log_and_raise_error(
          :error,
          "Failed to build actor ID for Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )

      {:request, error} ->
        log_and_raise_error(
          :error,
          "Failed to build request for Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.failed_precondition()
        )

      {:response, error} ->
        log_and_raise_error(
          :error,
          "Failed to invoke request for Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )
    end
  end

  defp dispatch_async(system_name, actor_name, action_name, message, stream) do
    with {:actor_id, actor_id} <- {:actor_id, build_actor_id(system_name, actor_name, message)},
         {:request, {:ok, request}} <-
           {:request, build_request(actor_id, system_name, action_name, message, async: true)},
         {:response, {:ok, :async}} <- {:response, invoke_request(request)} do
      server_send_reply(stream, %{})
    else
      {:actor_id, {:not_found, _}} ->
        log_and_raise_error(
          :warning,
          "Actor Not Found. The Actor probably does not exist or not implemented or the request params are incorrect!",
          GRPC.Status.not_found()
        )

      {:actor_id, error} ->
        log_and_raise_error(
          :error,
          "Failed to build actor ID for Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )

      {:request, error} ->
        log_and_raise_error(
          :error,
          "Failed to build request for Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )

      {:response, error} ->
        log_and_raise_error(
          :error,
          "Failed to invoke request for Actor #{system_name}:#{actor_name}. Details: #{inspect(error)}",
          GRPC.Status.unknown()
        )
    end
  end

  defp server_send_reply(stream, response) do
    if stream.grpc_type == :unary do
      response
    else
      Server.send_reply(stream, response)
    end
  end

  defp build_actor_id(system_name, actor_name, message) do
    with {:ok, %HostActor{actor: %Actor{settings: %ActorSettings{} = actor_settings}}} <-
           ActorRegistry.lookup(%ActorId{system: system_name, name: actor_name}) do
      build_actor_id_from_settings(system_name, actor_name, actor_settings, message)
    else
      {:not_found, _} ->
        log_and_raise_error(
          :warning,
          "Actor Not Found. The Actor probably does not exist or not implemented or the request params are incorrect!",
          GRPC.Status.not_found()
        )
    end
  end

  defp build_actor_id_from_settings(
         system_name,
         actor_name,
         %ActorSettings{kind: kind},
         _message
       )
       when kind in [:NAMED, :PROJECTION, :TASK] do
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
    module = message.__struct__
    descriptor_proto = apply(module, :descriptor, [])

    Enum.find_value(descriptor_proto.field, fn
      %Google.Protobuf.FieldDescriptorProto{
        name: name,
        options: %Google.Protobuf.FieldOptions{
          ctype: ctype,
          __pb_extensions__: ext
        }
      } ->
        Map.get(ext, {Spawn.Actors.PbExtension, :actor_id}, false) &&
          {ctype, String.to_atom(name)}

      _ ->
        nil
    end)
  end

  defp get_actor_id_name(:STRING, message, attribute), do: Map.get(message, attribute)

  defp get_actor_id_name(_ctype, message, attribute),
    do: "#{inspect(Map.get(message, attribute))}"

  defp build_request(nil, _, _, _, _), do: {:error, nil}

  defp build_request(actor_id, actor_system, action_name, message, opts) do
    async = Keyword.get(opts, :async, false)

    {:ok,
     %InvocationRequest{
       async: async,
       system: %ActorSystem{name: actor_system},
       actor: %Actor{id: actor_id},
       action_name: action_name,
       register_ref: actor_id.parent,
       payload: {:value, any_pack!(message)}
     }}
  end

  defp invoke_readiness(nil), do: {:error, :invalid_payload}

  defp invoke_readiness(request), do: CallerProducer.readiness(request)

  defp invoke_liveness(nil), do: {:error, :invalid_payload}

  defp invoke_liveness(request), do: CallerProducer.liveness(request)

  defp invoke_request(nil), do: {:error, :invalid_payload}

  defp invoke_request(request) do
    case CallerProducer.invoke(request) do
      {:ok, %ActorInvocationResponse{payload: {:value, %Google.Protobuf.Any{} = response}}} ->
        {:ok, unpack_unknown(response)}

      {:ok, %ActorInvocationResponse{payload: %Google.Protobuf.Any{} = response}} ->
        {:ok, unpack_unknown(response)}

      {:ok, %ActorInvocationResponse{payload: {:noop, %Spawn.Noop{}}}} ->
        {:ok, %Google.Protobuf.Empty{}}

      :async ->
        {:ok, %Google.Protobuf.Empty{}}

      error ->
        Logger.warning("Error during parse response. Details: #{inspect(error)}")
        {:error, error}
    end
  end

  defp log_and_raise_error(level, message, status) do
    Logger.log(level, message)
    raise GRPC.RPCError, status: status, message: message
  end

  defp handle_error(message, status) do
    log_and_raise_error(:error, message, status)
  end
end
