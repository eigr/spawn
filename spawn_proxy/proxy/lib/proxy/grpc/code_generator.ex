defmodule Proxy.Grpc.CodeGenerator do
  @moduledoc """
  TODO
  """

  alias Proxy.Grpc.Parser

  def compile(descriptors, actors) do
    with {:ok, descriptors} <- descriptors |> compile(),
         {:ok, _} <- generate_services(actors),
         {:ok, _} <- generate_endpoints(actors) do
      {:ok, descriptors, actors}
    else
      _ ->
        {:error, descriptors, actors}
    end
  end

  def build_spec({:ok, descriptors, actors} = _metadata) do
  end

  def build_spec({:error, _, _} = _metadata) do
    raise ArgumentError, "Fail to compile protobuf files"
  end

  defp compile(descriptors) do
    files =
      descriptors
      |> Parser.prepare()

    for {name, file} <- files do
      case do_compile(file) do
        modules when is_list(modules) ->
          Logger.debug("The #{name} descriptor has been compiled!")

        error ->
          Logger.warning("Fail to compile descriptor #{name}. Details: #{inspect(error)}")
      end
    end

    {:ok, descriptors}
  end

  defp generate_services(entities) do
    root_template_path =
      Application.get_env(
        :massa_proxy,
        :proxy_root_template_path,
        :code.priv_dir(:massa_proxy)
      )

    grpc_template_path =
      Path.expand(
        "./templates/grpc_service.ex.eex",
        root_template_path
      )

    for entity <- entities do
      name = Enum.join([normalize_service_name(entity.service_name), "Service"], ".")

      Stream.map(entity.services, fn service ->
        methods =
          service.methods
          |> Flow.from_enumerable()
          |> Flow.map(&normalize_method_name(&1.name))
          |> Enum.to_list()

        Logger.info("Generating Service #{name} with Methods: #{inspect(methods)}")

        original_methods = get_method_names(service)
        input_types = get_input_type(service)
        output_types = get_output_type(service)
        request_types = get_request_type(service)

        mod =
          get_module(
            grpc_template_path,
            mod_name: name,
            name: name,
            methods: methods,
            original_methods: original_methods,
            handler: "MassaProxy.Runtime.Grpc.Server.Dispatcher",
            entity_type: entity.entity_type,
            persistence_id: entity.persistence_id,
            service_name: entity.service_name,
            input_types: input_types,
            output_types: output_types,
            request_types: request_types
          )

        Logger.debug("Service Definition:\n#{mod}")
        do_compile(mod)
        Logger.debug("Service compilation finish!")
      end)
      |> Stream.run()
    end

    {:ok, entities}
  end

  defp generate_endpoints(entities) do
    root_template_path =
      Application.get_env(
        :massa_proxy,
        :proxy_root_template_path,
        :code.priv_dir(:massa_proxy)
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
        &Enum.join([normalize_service_name(&1.service_name), "Service.ProxyService"], ".")
      )
      |> Enum.to_list()

    mod =
      get_module(
        grpc_endpoint_template_path,
        service_names: services
      )

    Logger.debug("Endpoint Definition:\n#{mod}")
    do_compile(mod)
    Logger.debug("Endpoint compilation finish!")

    {:ok, entities}
  end

  defp do_compile(file) do
    Code.compile_string(file)
  rescue
    error in UndefinedFunctionError ->
      Logger.error("Error in Module definition. Make sure the service name is correct")
      raise error

    error ->
      Logger.error("Error during Service compilation phase #{inspect(error)}")
  end

  defp normalize_service_name(name) do
    name
    |> String.split(".")
    |> Stream.map(&Macro.camelize(&1))
    |> Enum.join(".")
  end

  defp normalize_method_name(name), do: Macro.underscore(name)

  defp get_module(filename, bindings \\ []), do: EEx.eval_file(filename, bindings)
end
