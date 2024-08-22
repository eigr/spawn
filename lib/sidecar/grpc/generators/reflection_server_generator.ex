defmodule Sidecar.Grpc.Generators.ReflectionServerGenerator do
  @moduledoc """
  Module for generating a gRPC reflection server module.

  This module implements the `ProtobufGenerate.Plugin` behaviour to generate a gRPC reflection server
  module that includes specified gRPC services for reflection purposes.

  """
  @behaviour ProtobufGenerate.Plugin

  alias Protobuf.Protoc.Generator.Util

  @impl true
  def template do
    """
    defmodule Sidecar.GRPC.Reflection.Server do

      defmodule V1 do
        use GrpcReflection.Server, version: :v1, services: [
          <%= for service_name <- @services do %>
            <%= service_name %>.Service,
          <% end %>
        ]
      end

      defmodule V1Alpha do
        use GrpcReflection.Server, version: :v1alpha, services: [
          <%= for service_name <- @services do %>
            <%= service_name %>.Service,
          <% end %>
        ]
      end
    end
    """
  end

  @impl true
  def generate(ctx, %Google.Protobuf.FileDescriptorProto{service: svcs} = _desc) do
    current_services = :persistent_term.get(:grpc_reflection_services, [])

    services = do_generate(ctx, svcs, current_services)

    :persistent_term.put(:grpc_reflection_services, services)

    {List.first(services),
     [
       services: services
     ]}
  end

  defp do_generate(_ctx, nil, current_services), do: current_services
  defp do_generate(_ctx, [], current_services), do: current_services

  defp do_generate(ctx, svcs, current_services) do
    svcs
    |> Enum.map(fn svc -> Util.mod_name(ctx, [Macro.camelize(svc.name)]) end)
    |> Kernel.++(current_services)
  end
end
