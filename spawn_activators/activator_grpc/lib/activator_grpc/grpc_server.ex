defmodule ActivatorGrpc.GrpcServer do
  @moduledoc false
  require Logger

  alias ActivatorGRPC.API.Reflection
  alias ActivatorGrpc.GrpcUtils, as: Util

  def child_spec(descriptors, entities) do
    {u_secs, spec} =
      :timer.tc(fn ->
        spec =
          with {:ok, descriptors} <- descriptors |> compile(),
               {:ok, _} <- generate_services(entities),
               {:ok, _} <- generate_endpoints(entities) do
            build_child_spec(descriptors, entities)
          else
            _ ->
              Logger.error("Error during gRPC Server initialization")
              nil
          end

        spec
      end)

    Logger.info("Started gRPC Server in #{u_secs / 1_000_000}ms")
    spec
  end

  defp compile(descriptors) do
    files =
      descriptors
      |> Reflection.prepare()

    for {name, file} <- files do
      case Util.compile(file) do
        modules when is_list(modules) ->
          Logger.debug("Compiled #{name} module!")

        _ ->
          Logger.debug("Fail to compile service")
      end
    end

    {:ok, descriptors}
  end

  defp generate_services(entities) do
    root_template_path =
      Application.get_env(
        :activator_grpc,
        :proxy_root_template_path,
        :code.priv_dir(:activator_grpc)
      )

    grpc_template_path =
      Path.expand(
        "./templates/grpc_service.ex.eex",
        root_template_path
      )

    for entity <- entities do
      name = Enum.join([Util.normalize_service_name(entity.service_name), "Service"], ".")

      Stream.map(entity.services, fn service ->
        methods =
          service.methods
          |> Flow.from_enumerable()
          |> Flow.map(&Util.normalize_method_name(&1.name))
          |> Enum.to_list()

        Logger.info("Generating Service #{name} with Methods: #{inspect(methods)}")

        original_methods = get_method_names(service)
        input_types = get_input_type(service)
        output_types = get_output_type(service)
        request_types = get_request_type(service)

        mod =
          Util.get_module(
            grpc_template_path,
            mod_name: name,
            name: name,
            methods: methods,
            original_methods: original_methods,
            handler: "MassaProxy.Runtime.Grpc.Server.Dispatcher",
            service_name: entity.service_name,
            input_types: input_types,
            output_types: output_types,
            request_types: request_types
          )

        Logger.debug("Service Definition:\n#{mod}")
        Util.compile(mod)
        Logger.debug("Service compilation finish!")
      end)
      |> Stream.run()
    end

    {:ok, entities}
  end

  defp generate_endpoints(entities) do
    root_template_path =
      Application.get_env(
        :activator_grpc,
        :proxy_root_template_path,
        :code.priv_dir(:activator_grpc)
      )

    grpc_endpoint_template_path =
      Path.expand(
        "./templates/grpc_endpoint.ex.eex",
        root_template_path
      )

    services =
      entities
      |> Flow.from_enumerable()
      |> Flow.map(
        &Enum.join([Util.normalize_service_name(&1.service_name), "Service.ProxyService"], ".")
      )
      |> Enum.to_list()

    mod =
      Util.get_module(
        grpc_endpoint_template_path,
        service_names: services
      )

    Logger.debug("Endpoint Definition:\n#{mod}")
    Util.compile(mod)
    Logger.debug("Endpoint compilation finish!")

    {:ok, entities}
  end

  defp build_child_spec(_descriptors, _entities) do
    Application.put_env(:grpc, :start_server, true, persistent: true)

    opts = get_grpc_options()
    grpc_spec = {GRPC.Server.Supervisor, opts}
    # http_spec = HttpRouter.child_spec(entities)
    # reflection_spec = MassaProxy.Reflection.Server.child_spec(descriptors)
    grpc_spec
  end

  defp get_grpc_options() do
    port = Application.get_env(:activator_grpc, :proxy_port, 9009)

    if Application.get_env(:activator_grpc, :tls) do
      cert_path = Application.get_env(:activator_grpc, :tls_cert_path)
      key_path = Application.get_env(:activator_grpc, :tls_key_path)
      cred = GRPC.Credential.new(ssl: [certfile: cert_path, keyfile: key_path])

      {ActivatorGrpc.Server.Grpc.ProxyEndpoint, port, cred: cred}
    else
      {ActivatorGrpc.Server.Grpc.ProxyEndpoint, port}
    end
  end

  defp get_method_names(services),
    do:
      Enum.reduce(services.methods, %{}, fn method, acc ->
        Map.put(
          acc,
          Util.normalize_method_name(method.name),
          method.name
        )
      end)

  defp get_input_type(services),
    do:
      Enum.reduce(services.methods, %{}, fn method, acc ->
        Map.put(
          acc,
          Util.normalize_method_name(method.name),
          String.replace_leading(Util.normalize_service_name(method.input_type), ".", "")
        )
      end)

  defp get_output_type(services),
    do:
      Enum.reduce(services.methods, %{}, fn method, acc ->
        Map.put(
          acc,
          Util.normalize_method_name(method.name),
          String.replace_leading(Util.normalize_service_name(method.output_type), ".", "")
        )
      end)

  defp get_request_type(services),
    do:
      Enum.reduce(services.methods, %{}, fn method, acc ->
        Map.put(acc, Util.normalize_method_name(method.name), get_type(method))
      end)

  defp get_type(method) do
    type =
      cond do
        method.unary == true -> "unary"
        method.streamed == true -> "streamed"
        method.stream_in == true -> "stream_in"
        method.stream_out == true -> "stream_out"
      end

    type
  end
end
