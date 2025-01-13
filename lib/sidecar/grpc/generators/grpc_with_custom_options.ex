defmodule Sidecar.GRPC.Generators.GRPCWithCustomOptions do
  # ref: https://github.com/elixir-protobuf/protobuf/blob/main/lib/protobuf/protoc/generator/grpc.ex
  @moduledoc """
  Plugin to Generate gRPC code from protbuf service definitions, this plugin outputs any extension options
  on service methods as a param to [`GRPC.Service.rpc/4`](https://github.com/drowzy/grpc/blob/grpc_transcoding/lib/grpc/service.ex#L56)
  """

  @behaviour ProtobufGenerate.Plugin

  alias Protobuf.Protoc.Generator.Util

  @impl true
  def template do
    """
    <%= if @render do %>
      defmodule <%= @module %>.Service do
        use GRPC.Service, name: <%= inspect(@service_name) %>, protoc_gen_elixir_version: "<%= @version %>"

        <%= if @descriptor_fun_body do %>
        def descriptor do
          # credo:disable-for-next-line
          <%= @descriptor_fun_body %>
        end
        <% end %>

        <%= for {method_name, input, output, options} <- @methods do %>
        rpc :<%= method_name %>, <%= input %>, <%= output %>, <%= options %>
        <% end %>
      end

      defmodule <%= @module %>.Stub do
        use GRPC.Stub, service: <%= @module %>.Service
      end
    <% end %>
    """
  end

  @impl true
  def generate(ctx, %Google.Protobuf.FileDescriptorProto{service: [_ | _] = svcs} = desc) do
    for svc <- svcs do
      mod_name = Util.mod_name(ctx, [Macro.camelize(svc.name)])
      name = Util.prepend_package_prefix(ctx.package, svc.name)

      descriptor_fun_body =
        if ctx.gen_descriptors? do
          Util.descriptor_fun_body(desc)
        else
          nil
        end

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
         render: true,
         module: mod_name,
         service_name: name,
         methods: methods,
         descriptor_fun_body: descriptor_fun_body,
         version: Util.version()
       ]}
    end
  end

  def generate(_ctx, _opts), do: {"unknown", [render: false]}

  defp service_arg(type, _streaming? = true), do: "stream(#{type})"
  defp service_arg(type, _streaming?), do: type

  defp opts(nil), do: %{}

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
