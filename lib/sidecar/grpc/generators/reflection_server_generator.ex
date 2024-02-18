defmodule Sidecar.Grpc.Generators.ReflectionServerGenerator do
  @moduledoc """
  TODO
  """
  @behaviour ProtobufGenerate.Plugin

  alias Protobuf.Protoc.Generator.Util

  @impl true
  def template do
    """
    defmodule Sidecar.GRPC.Reflection.Server do
      @moduledoc since: "1.2.1"
      use GrpcReflection.Server, version: :v1, services: [
        <%= for service_name <- @services do %>
          <%= service_name %>.Service,
        <% end %>
      ]

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
