defmodule Sidecar.GRPC.Generators.GeneratorAccumulator do
  @moduledoc """
  Module for generating a gRPC proxy endpoint module.

  This module implements the `ProtobufGenerate.Plugin` behaviour to generate a gRPC proxy endpoint
  module that includes specified gRPC services.

  """
  @behaviour ProtobufGenerate.Plugin

  alias Protobuf.Protoc.Generator.Util
  require Logger

  @impl true
  def template do
    ""
  end

  @impl true
  def generate(ctx, %Google.Protobuf.FileDescriptorProto{service: svcs} = _desc) do
    current_services = :persistent_term.get(:grpc_services, [])
    descriptors = (:persistent_term.get(:proto_file_descriptors, []) ++ svcs) |> Enum.uniq()

    services = services_to_module(ctx, svcs, current_services)

    :persistent_term.put(:grpc_services, services)
    :persistent_term.put(:proto_file_descriptors, descriptors)
    :persistent_term.put(:proto_file_ctx, ctx)

    {"ProxyEndpoint",
     [
       services: services
     ]}
  end

  defp services_to_module(_ctx, nil, current_services), do: current_services
  defp services_to_module(_ctx, [], current_services), do: current_services

  defp services_to_module(ctx, svcs, current_services) do
    svcs
    |> Enum.map(fn svc -> Util.mod_name(ctx, [Macro.camelize(svc.name)]) end)
    |> Kernel.++(current_services)
  end
end
