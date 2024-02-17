defmodule Sidecar.Grpc.Reflection do
  @moduledoc """
  This module is responsible for handling all requests
  with a view to contract reflection (reflection.proto)
  """
  use GenServer
  require Logger

  alias Google.Protobuf.{FileDescriptorProto}

  alias Grpc.Reflection.V1alpha.{
    ErrorResponse,
    FileDescriptorResponse,
    ListServiceResponse,
    ServerReflectionResponse,
    ServiceResponse
  }

  def child_spec(state) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [state]}
    }
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:list_services, _from, state) do
    service_response =
      state
      |> Enum.map(&extract_info/1)
      |> Enum.reduce(fn -> [] end, fn s, acc ->
        acc ++ [s]
      end)
      |> Enum.to_list()
      |> List.flatten()

    response =
      ServerReflectionResponse.new(
        message_response:
          {:list_services_response, ListServiceResponse.new(service: service_response)}
      )

    {:reply, response, state}
  end

  @impl true
  def handle_call({:file_by_filename, filename}, _from, state) do
    files =
      state
      |> Enum.filter(fn descriptor -> descriptor.name =~ filename end)
      |> Enum.map(fn descriptor -> FileDescriptorProto.encode(descriptor) end)
      |> Enum.reduce(fn -> [] end, fn s, acc ->
        acc ++ [s]
      end)
      |> Enum.to_list()
      |> List.flatten()

    response =
      ServerReflectionResponse.new(
        message_response:
          {:file_descriptor_response, FileDescriptorResponse.new(file_descriptor_proto: files)}
      )

    {:reply, response, state}
  end

  @impl true
  def handle_call({:file_containing_symbol, symbol}, _from, state) do
    resp =
      with {:fail, :empty} <- contains_service(state, symbol),
           {:fail, :empty} <- contains_message_type(state, symbol) do
        response =
          ServerReflectionResponse.new(
            message_response:
              {:error_response,
               ErrorResponse.new(error_code: 5, error_message: "Symbol Not Found")}
          )

        response
      else
        {:ok, description} ->
          response =
            ServerReflectionResponse.new(
              message_response:
                {:file_descriptor_response,
                 FileDescriptorResponse.new(file_descriptor_proto: description)}
            )

          response
      end

    {:reply, resp, state}
  end

  # Client API
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def list_services() do
    GenServer.call(__MODULE__, :list_services)
  end

  def find_by_filename(filename) do
    GenServer.call(__MODULE__, {:file_by_filename, filename})
  end

  def find_by_symbol(symbol) do
    GenServer.call(__MODULE__, {:file_containing_symbol, symbol})
  end

  # Private
  defp contains_service(state, symbol) do
    description =
      state
      |> Enum.map(&get_service(&1, symbol))
      |> Enum.reduce(fn -> [] end, fn s, acc ->
        acc ++ [s]
      end)
      |> Enum.to_list()
      |> List.flatten()

    if Enum.empty?(description) do
      {:fail, :empty}
    else
      {:ok, description}
    end
  end

  defp contains_message_type(state, symbol) do
    description =
      state
      |> Enum.map(&get_messages(&1, symbol))
      |> Enum.reduce(fn -> [] end, fn s, acc ->
        if s != nil || s != [] do
          acc ++ [s]
        else
          acc
        end
      end)
      |> Enum.to_list()
      |> List.flatten()

    if Enum.empty?(description) do
      {:fail, :empty}
    else
      {:ok, Enum.filter(description, &(!is_nil(&1)))}
    end
  end

  defp get_service(descriptor, symbol) do
    services = extract_services(descriptor)

    svcs =
      services
      |> Enum.filter(fn service -> symbol =~ service.name end)
      |> Enum.map(fn _ -> FileDescriptorProto.encode(descriptor) end)
      |> Enum.reduce(fn -> [] end, fn s, acc ->
        acc ++ [s]
      end)
      |> Enum.to_list()

    svcs
  end

  defp get_messages(descriptor, symbol) do
    message_types = extract_messages(descriptor)

    if !Enum.empty?(message_types) do
      types =
        message_types
        |> Enum.filter(fn message -> symbol =~ message.name end)
        |> Enum.map(fn _ -> FileDescriptorProto.encode(descriptor) end)
        |> Enum.reduce(fn -> [] end, fn s, acc ->
          [s] ++ acc
        end)
        |> Enum.to_list()

      types
    end
  end

  defp extract_info(descriptor) do
    package = descriptor.package
    services = extract_services(descriptor)

    svcs =
      services
      |> Enum.map(fn service -> ServiceResponse.new(name: "#{package}.#{service.name}") end)
      |> Enum.reduce(fn -> [] end, fn s, acc ->
        acc ++ [s]
      end)
      |> Enum.to_list()

    svcs
  end

  defp extract_services(file) do
    file.service
    |> Enum.from_enumerable()
    |> Enum.to_list()
  end

  defp extract_messages(file) do
    file.message_type
    |> Flow.from_enumerable()
    |> Enum.to_list()
  end
end
