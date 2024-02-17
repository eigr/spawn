defmodule Sidecar.Grpc.Generators.HandlerGenerator do
  @moduledoc """
  TODO
  """
  @behaviour ProtobufGenerate.Plugin

  alias Protobuf.Protoc.Generator.Util

  @impl true
  def template do
    """
    defmodule <%= @module %>.ActorDispatcher do
      @moduledoc since: "1.2.1"
      use GRPC.Server, service: <%= @service_name %>

      <%= for {method_name, input, output} <- @methods do %>
        @spec <%= Macro.underscore(method_name) %>(<%= input %>.t(), GRPC.Server.Stream.t()) :: <%= output %>.t()
        def <%= method_name %>(message, stream) do
          request = %{
            system: <%= inspect(@actor_system) %>,
            actor_name: <%= inspect(@actor_name) %>,
            action_name: <%= inspect(method_name) %>,
            input: message,
            stream: stream
          }

          Dispatcher.dispatch(request)
        end
      <% end %>

    end
    """
  end

  @impl true
  def generate(ctx, %Google.Protobuf.FileDescriptorProto{service: svcs} = desc) do
    for svc <- svcs do
      mod_name = Util.mod_name(ctx, [Macro.camelize(svc.name)])
      actor_name = Macro.camelize(svc.name)
      # TODO get system name here from configuration
      actor_system = "spawn-system"
      name = Util.prepend_package_prefix(ctx.package, svc.name)

      methods =
        for m <- svc.method do
          input = service_arg(Util.type_from_type_name(ctx, m.input_type), m.client_streaming)
          output = service_arg(Util.type_from_type_name(ctx, m.output_type), m.server_streaming)

          options =
            m.options
            |> opts()
            |> inspect(limit: :infinity)

          {m.name, input, output, options}
        end

      {mod_name,
       [
         module: mod_name,
         actor_system: actor_system,
         actor_name: actor_name,
         service_name: name,
         methods: methods,
         version: Util.version()
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
