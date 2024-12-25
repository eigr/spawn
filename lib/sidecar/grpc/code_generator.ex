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
  alias Mix.Tasks.Protobuf.Generate

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

    actors_path = Keyword.get(opts, :protos_path, Config.get(:grpc_actors_protos_path))
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

    user_defined_proto_files_list = list_files_with_full_path_by_extensions(actors_path, ".proto")

    Logger.info(
      "Found #{length(user_defined_proto_files_list)} ActorHost Protocol Buffers to compile... (#{inspect(user_defined_proto_files_list)})"
    )

    invoker_helper =
      if Code.ensure_loaded?(SpawnSdk) do
        ["--plugin=Sidecar.GRPC.Generators.ActorInvoker"]
      else
        []
      end

    if length(user_defined_proto_files_list) > 0 do
      protoc_options =
        [
          "--include-path=#{include_path}",
          "--include-path=#{File.cwd!()}/priv/protos/google/protobuf",
          "--include-path=#{File.cwd!()}/priv/protos/google/api",
          "--generate-descriptors=true",
          "--output-path=#{output_path}",
          "--plugin=#{grpc_generator_plugin}",
          "--plugin=#{handler_generator_plugin}",
          "--plugin=Sidecar.GRPC.Generators.ServiceGenerator",
          "--plugin=Sidecar.Grpc.Generators.ReflectionServerGenerator"
        ] ++
          user_defined_proto_files_list ++ invoker_helper

      _ = Generate.run(protoc_options)

      :ok
    else
      {:ok, :nothing_to_compile}
    end
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
