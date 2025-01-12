defmodule Sidecar.GRPC.CodeGenerator do
  @moduledoc """
  Module for generating gRPC code from Protobuf files.

  This module provides functionality to compile Protobuf files and generate gRPC-related code.
  It supports both gRPC and HTTP transcoding code generation.

  ## Usage

  1. Call `compile_protos/1` to generate gRPC code from Protobuf files.
  2. Ensure that Protobuf files are placed in the specified directory (`priv/protos` by default).

  """
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config
  alias Spawn.Actors.ActorViewOption
  alias Protobuf.Protoc.Generator.Util
  alias Mix.Tasks.Protobuf.Generate
  alias Spawn.Utils.AnySerializer

  @doc """
    Compiles Protobuf files and generates gRPC-related code.

    ### Options:

    - `:protos_path` - Include path of protobufs to generate (default: "priv/protos").
    - `:output_path` - Output path for generated code (default: "priv/protos/modules").
    - `:http_transcoding_enabled` - Enable HTTP transcoding (default: true).

    ### Example:

    ```elixir
    Sidecar.Grpc.CodeGenerator.compile_protos(output_path: "custom_output", http_transcoding_enabled: false)

  """
  def compile_protos(opts \\ []) do
    Logger.debug("Compiling ActorHost Protocol Buffers...")

    include_path = Keyword.get(opts, :protos_path, Config.get(:grpc_include_protos_path))
    output_path = Keyword.get(opts, :output_path, Config.get(:grpc_compiled_modules_path))

    transcoding_enabled? =
      Keyword.get(opts, :http_transcoding_enabled, Config.get(:grpc_http_transcoding_enabled))

    {grpc_generator_plugin, handler_generator_plugin} =
      if transcoding_enabled? do
        {Sidecar.GRPC.Generators.GRPCWithCustomOptions,
         Sidecar.GRPC.Generators.HandlerTranscodingGenerator}
      else
        {ProtobufGenerate.Plugins.GRPC, Sidecar.GRPC.Generators.HandlerGenerator}
      end

    include_files_path = list_files_with_full_path_by_extensions(include_path, ".proto")

    invoker_helper =
      if Code.ensure_loaded?(SpawnSdk) do
        ["--plugin=Sidecar.GRPC.Generators.ActorInvoker"]
      else
        []
      end

    spawn_protos_dir = Application.app_dir(:spawn, "priv/protos")

    if Enum.count(include_files_path) > 0 do
      protoc_options =
        [
          "--include-path=#{include_path}",
          "--include-path=#{spawn_protos_dir}",
          "--generate-descriptors=true",
          "--one-file-per-module",
          "--output-path=#{output_path}",
          "--plugin=#{grpc_generator_plugin}",
          "--plugin=#{handler_generator_plugin}",
          "--plugin=Sidecar.GRPC.Generators.GeneratorAccumulator"
        ] ++
          invoker_helper ++ include_files_path

      _ = Generate.run(protoc_options)

      :ok
    else
      {:ok, :nothing_to_compile}
    end
  end

  def after_compile_hook do
    svcs = :persistent_term.get(:proto_file_descriptors, [])
    current_services = :persistent_term.get(:grpc_services, [])

    dispatchers =
      current_services
      |> Enum.reduce("", fn svc, acc -> "#{svc}.ActorDispatcher,\n#{acc}" end)

    reflections =
      current_services
      |> Enum.reduce("", fn svc, acc -> "#{svc}.Service,\n#{acc}" end)

    compile_proxy_endpoint(dispatchers)
    compile_reflections(reflections)
    put_actor_definition_settings(svcs)

    :persistent_term.erase(:proto_file_descriptors)
    :persistent_term.erase(:grpc_services)

    :ok
  end

  defp compile_reflections(reflections) do
    Code.compile_string("""
    defmodule Sidecar.GRPC.Reflection.Server do
      defmodule V1 do
        use GrpcReflection.Server, version: :v1, services: [
          #{reflections}
        ]
      end

      defmodule V1Alpha do
        use GrpcReflection.Server, version: :v1alpha, services: [
          #{reflections}
        ]
      end
    end
    """)
  end

  defp compile_proxy_endpoint(endpoints) do
    Code.compile_string("""
    defmodule Sidecar.GRPC.ProxyEndpoint do
      use GRPC.Endpoint

      intercept(GRPC.Server.Interceptors.Logger)

      services = [
        #{endpoints}
      ]

      services =
        [
          Sidecar.GRPC.Reflection.Server.V1,
          Sidecar.GRPC.Reflection.Server.V1Alpha,
          Spawn.Actors.Healthcheck.HealthCheckActor.ActorDispatcher
        ] ++ services

      run(services)
    end
    """)
  end

  defp put_actor_definition_settings(svcs) do
    Enum.each(svcs, fn svc ->
      options = svc.options || %{}
      option_extensions = Map.get(options, :__pb_extensions__, %{})
      actor_opts = Map.get(option_extensions, {Spawn.Actors.PbExtension, :actor})

      if not is_nil(actor_opts) do
        :persistent_term.put("actor-#{svc.name}", actor_opts)
      end

      Enum.each(svc.method, fn method ->
        method_options = method.options || %{}
        method_option_extensions = Map.get(method_options, :__pb_extensions__, %{})

        case Map.get(method_option_extensions, {Spawn.Actors.PbExtension, :view}) do
          %ActorViewOption{} = option ->
            output_type = AnySerializer.normalize_package_name(method.output_type)
            input_type = AnySerializer.normalize_package_name(method.input_type)

            descriptor = apply(output_type, :descriptor, [])

            field = descriptor.field |> Enum.find(fn field -> field.name == option.map_to end)

            type_name = AnySerializer.normalize_package_name(field.type_name)

            # let the proxy know that there is a
            :persistent_term.put("view-#{svc.name}-#{method.name}", %{
              query: option.query,
              view_name: method.name,
              query_result_type: type_name,
              map_to: option.map_to,
              page_size: option.page_size,
              output_type: output_type,
              input_type: input_type
            })

            :ok

          _ ->
            nil
        end
      end)
    end)
  end

  @doc """
  Loads Elixir modules from the specified directory with a '.pb.ex' file extension.

  ## Parameters

  - `opts` (KeywordList): Options for loading modules.
    - `:output_path` (String): Path to the directory containing the modules. Default is "#{File.cwd!()}/priv/protos/modules".

  ## Returns

  A list of strings, where each string represents the content of an Elixir module file.

  ## Examples

  ```elixir
  opts = [output_path: "/path/to/modules"]
  modules = load_modules(opts)
  IO.inspect(modules)

  This example loads Elixir modules from the specified directory "/path/to/modules" and prints the content of each module.

  """
  def load_modules(opts \\ []) do
    path = Keyword.get(opts, :output_path, Config.get(:grpc_compiled_modules_path))

    user_defined_modules_files = list_files_with_full_path_by_extensions(path, ".pb.ex")

    modules = Enum.map(user_defined_modules_files, fn full_path -> File.read!(full_path) end)

    Logger.info("Found #{length(modules)} ActorHost Contract Modules to load...")

    {:ok, modules}
  end

  @doc """
  Compiles an Elixir module generated from Protobuf files and returns the compiled code.

  ### Parameters:

  - `module` - The String of Elixir module code generated from Protobuf files.

  ### Returns:

  The compiled Elixir code.

  ### Example:

  ```elixir
  module_code = Sidecar.Grpc.CodeGenerator.compile_modules(generated_code)

  Raises:

  Raises an error if there are issues during the compilation process.

  """
  def compile_modules(modules) when is_list(modules) do
    Logger.debug("Compiling ActorHost contract modules...")
    Enum.each(modules, &compile_modules/1)
  end

  def compile_modules(module), do: do_compile(module)

  defp do_compile(module) do
    Code.compile_string(module)
  rescue
    error in UndefinedFunctionError ->
      Logger.error("Error in Module definition. Make sure the service name is correct")
      raise error

    error ->
      Logger.error("Error during Service compilation phase #{inspect(error)}")
  end

  defp list_files_with_full_path_by_extensions(directory, extension) do
    case ls_r(directory) do
      [] ->
        Logger.warning("Not found any protos on #{inspect(directory)}")
        []

      files ->
        files
        |> Enum.filter(&String.ends_with?(&1, extension))
        |> Enum.sort()
    end
  end

  def ls_r(path \\ ".") do
    cond do
      File.regular?(path) ->
        [path]

      File.dir?(path) ->
        File.ls!(path)
        |> Enum.map(&Path.join(path, &1))
        |> Enum.map(&ls_r/1)
        |> Enum.concat()

      true ->
        []
    end
  end
end
