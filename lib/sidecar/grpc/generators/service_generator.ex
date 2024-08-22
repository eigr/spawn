defmodule Sidecar.GRPC.Generators.ServiceGenerator do
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
    """
    defmodule Sidecar.GRPC.ProxyEndpoint do
      use GRPC.Endpoint

      intercept(GRPC.Server.Interceptors.Logger)

      services = [
    <%= for service_name <- @services do %>
      <%= service_name %>.ActorDispatcher,
    <% end %>
      ]

      services =
        [
          Sidecar.GRPC.Reflection.Server.V1,
          Sidecar.GRPC.Reflection.Server.V1Alpha,
          Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.ActorDispatcher
        ] ++ services

      run(services)
    end
    """
  end

  @impl true
  def generate(ctx, %Google.Protobuf.FileDescriptorProto{service: svcs} = _desc) do
    current_services = :persistent_term.get(:grpc_services, [])

    services = do_generate(ctx, svcs, current_services)

    :persistent_term.put(:grpc_services, services)

    {"ProxyEndpoint",
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
