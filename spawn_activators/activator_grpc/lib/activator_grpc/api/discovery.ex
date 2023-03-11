defmodule ActivatorGrpc.Api.Discovery do
  @moduledoc false
  require Logger

  alias Google.Protobuf.FileDescriptorSet
  alias ActivatorGrpc.GrpcUtils, as: Util

  def discover(%{entities: _entities, proto_file_path: path} = args) do
    with {:load_file, {:ok, proto}} <- {:load_file, File.read(path)},
         {:parse, {:ok, descriptors, endpoints}} <-
           {:parse, parse(%{args | proto: proto})} do
      {:ok, descriptors, endpoints}
    else
      {:load_file, {:error, reason}} ->
        Logger.error("Failure to load protobuf file descriptor. Details: #{inspect(reason)}")
        {:error, {:load_file, reason}}

      {:parse, error} ->
        Logger.error("Failure to parse protobuf file descriptor. Details: #{inspect(error)}")
        {:error, {:parse, error}}
    end
  end

  defp parse(args) do
    args
    |> validate()
    |> to_endpoints()
  end

  defp validate(args) do
    entities = args.entities

    if Enum.empty?(entities) do
      Logger.error("No entities were reported by the discover call!")
      raise "No entities were reported by the discover call!"
    end

    if !is_binary(args.proto) do
      Logger.error("No descriptors found")
      raise "No descriptors found!"
    end

    {:ok, args}
  end

  defp to_endpoints({:ok, args}) do
    entities = args.entities
    descriptor = FileDescriptorSet.decode(args.proto)
    file_descriptors = descriptor.file

    endpoints =
      entities
      |> Flow.from_enumerable()
      |> Flow.map(&build_endpoint(&1, file_descriptors))
      |> Enum.to_list()

    Logger.debug("Found #{Enum.count(endpoints)} Endpoints to processing.")
    {:ok, file_descriptors, endpoints}
  end

  defp build_endpoint(entity, file_descriptors) do
    messages =
      file_descriptors
      |> Flow.from_enumerable()
      |> Flow.map(&extract_messages/1)
      |> Enum.reduce([], fn elem, acc ->
        acc ++ [elem]
      end)
      |> List.flatten()

    services =
      file_descriptors
      |> Flow.from_enumerable()
      |> Flow.map(&extract_services(&1, entity.service_name))
      |> Enum.reduce([], fn elem, acc ->
        acc ++ [elem]
      end)
      |> List.flatten()

    %{
      service_name: entity.service_name,
      messages: Enum.filter(messages, fn x -> x != [] end),
      services: Enum.filter(services, fn x -> x != [] end)
    }
  end

  defp extract_messages(file) do
    file.message_type
    |> Flow.from_enumerable()
    |> Flow.map(&to_message_item/1)
    |> Enum.reduce([], fn elem, acc ->
      acc ++ [elem]
    end)
    |> List.flatten()
  end

  defp extract_services(file, service_name) do
    name =
      service_name
      |> String.split(".")
      |> List.last()

    file.service
    |> Flow.from_enumerable()
    |> Flow.filter(fn service ->
      String.trim(service.name) != "" && service.name == name
    end)
    |> Flow.map(&to_service_item/1)
    |> Enum.reduce([], fn elem, acc ->
      acc ++ [elem]
    end)
    |> List.flatten()
  end

  defp to_message_item(message) do
    attributes =
      message.field
      |> Flow.from_enumerable()
      |> Flow.map(&extract_field_attributes/1)
      |> Enum.to_list()

    %{name: message.name, attributes: attributes}
  end

  defp to_service_item(service) do
    methods =
      service.method
      |> Flow.from_enumerable()
      |> Flow.map(&extract_service_method/1)
      |> Enum.to_list()

    %{name: service.name, methods: methods}
  end

  defp extract_field_attributes(field) do
    type_options =
      if field.options != nil && field.options.ctype != nil do
        field.options.ctype
      end

    %{
      name: field.name,
      number: field.number,
      type: field.type,
      label: field.label,
      options: %{type: type_options}
    }
  end

  defp extract_service_method(method) do
    http_options =
      if method.options != nil do
        http_rules = Util.get_http_rule(method)
        Logger.debug("Mehod Options: #{inspect(http_rules)}")

        %{type: "http", data: http_rules}
      end

    svc = %{
      name: method.name,
      unary: is_unary(method),
      streamed: is_streamed(method),
      input_type: method.input_type,
      output_type: method.output_type,
      stream_in: method.client_streaming,
      stream_out: method.server_streaming,
      options: [http_options]
    }

    Logger.debug("Service mapped #{inspect(svc)}")
    svc
  end

  defp is_unary(method) do
    if method.client_streaming == false && method.server_streaming == false do
      true
    else
      false
    end
  end

  defp is_streamed(method) do
    if method.client_streaming == true && method.server_streaming == true do
      true
    else
      false
    end
  end
end
