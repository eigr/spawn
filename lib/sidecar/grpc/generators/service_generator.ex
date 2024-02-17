defmodule Sidecar.Grpc.Generators.ServiceGenerator do
  @moduledoc """
  TODO
  """
  @behaviour ProtobufGenerate.Plugin

  alias Protobuf.Protoc.Generator.Util

  @impl true
  def template do
    """
    defmodule Sidecar.Grpc.ProxyEndpoint do
      @moduledoc false
      use GRPC.Endpoint

      intercept(GRPC.Logger.Server)

      services = [
        #MassProxy.Reflection.Service,
    <%= for service_name <- @services do %>
      <%= service_name %>,
    <% end %>
      ]

      run(services)
    end
    """
  end

  @impl true
  def generate(ctx, %Google.Protobuf.FileDescriptorProto{service: svcs} = desc) do
    for svc <- svcs do
      mod_name = Util.mod_name(ctx, [Macro.camelize(svc.name)])

      {mod_name,
       [
         service_name: mod_name
       ]}
    end
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
