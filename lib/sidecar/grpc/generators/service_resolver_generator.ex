defmodule Sidecar.GRPC.Generators.ServiceResolverGenerator do
  @moduledoc """
  Module for generating a gRPC service resolver module.

  This module implements the `ProtobufGenerate.Plugin` behaviour to generate a gRPC service resolver
  module that provides methods for resolving gRPC services and their descriptors.

  """
  @behaviour ProtobufGenerate.Plugin

  alias Protobuf.Protoc.Generator.Util

  @impl true
  def template do
    """
    defmodule Sidecar.GRPC.ServiceResolver do
      @moduledoc since: "1.2.1"

      @actors [
        <%= for {actor_name, %{service_name: service_name}} <- @actors do %>
          {
            <%= inspect(actor_name) %>,
            %{
              service_name: <%= inspect(service_name) %>,
              service_module: <%= service_name %>.Service
            }
          }
        <% end %>
      ]

      def has_actor?(actor_name) do
        Enum.any?(@actors, fn {name, _} -> actor_name == name end)
      end

      def get_descriptor(actor_name) do
        actor_attributes =
          Enum.filter(@actors, fn {name, _} -> actor_name == name end)
          |> Enum.map(fn {_name, attributes} -> attributes end)
          |> List.first()

        mod = Map.get(actor_attributes, :service_module)
        mod.descriptor()
        |> Map.get(:service)
        |> Enum.filter(fn %Google.Protobuf.ServiceDescriptorProto{name: name} -> actor_name == name end)
        |> List.first()
      end

    end
    """
  end

  @impl true
  def generate(ctx, %Google.Protobuf.FileDescriptorProto{service: svcs} = _desc) do
    actors =
      Enum.map(svcs, fn svc ->
        service_name = Util.mod_name(ctx, [Macro.camelize(svc.name)])
        actor_name = Macro.camelize(svc.name)

        methods =
          for m <- svc.method do
            input = service_arg(Util.type_from_type_name(ctx, m.input_type), m.client_streaming)
            output = service_arg(Util.type_from_type_name(ctx, m.output_type), m.server_streaming)

            options =
              m.options
              |> opts()
              |> inspect(limit: :infinity)

            {m.name, input, output, options, m.client_streaming, m.server_streaming}
          end

        {
          actor_name,
          %{
            service_name: service_name,
            methods: methods
          }
        }
      end)

    {name, _} = List.first(actors)

    {name,
     [
       actors: actors
     ]}
  end

  defp service_arg(type, _streaming? = true), do: "stream(#{type})"
  defp service_arg(type, _streaming?), do: type

  defp opts(%Google.Protobuf.MethodOptions{__pb_extensions__: extensions})
       when extensions == %{} do
    %{}
  end

  defp opts(%Google.Protobuf.MethodOptions{__pb_extensions__: extensions}) do
    for {{type, field}, value} <- extensions, into: %{} do
      {field, %{type: type, value: value}}
    end
  end
end
