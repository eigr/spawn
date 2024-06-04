defmodule Sidecar.GRPC.Generators.ServiceGenerator do
  @moduledoc """
  Module for generating a gRPC proxy endpoint module.

  This module implements the `ProtobufGenerate.Plugin` behaviour to generate a gRPC proxy endpoint
  module that includes specified gRPC services.

  """
  @behaviour ProtobufGenerate.Plugin

  alias Protobuf.Protoc.Generator.Util

  @impl true
  def template do
    """
    defmodule Sidecar.GRPC.ProxyEndpoint do
      @moduledoc false
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
          Sidecar.Grpc.Healthcheck.HealthcheckHandler.Actordispatcher
        ] ++ services

      run(services)
    end
    """
  end

  @impl true
  def generate(ctx, %Google.Protobuf.FileDescriptorProto{service: svcs} = _desc) do
    services = Enum.map(svcs, fn svc -> Util.mod_name(ctx, [Macro.camelize(svc.name)]) end)

    {List.first(services),
     [
       services: services
     ]}
  end
end
