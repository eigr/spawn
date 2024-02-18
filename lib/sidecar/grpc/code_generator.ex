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

  alias Mix.Tasks.Protobuf.Generate

  @doc """
    Compiles Protobuf files and generates gRPC-related code.

    ### Options:

    - `:output_path` - Output path for generated code (default: "priv/protos/modules").
    - `:http_transcoding_enabled` - Enable HTTP transcoding (default: true).

    ### Example:

    ```elixir
    Sidecar.Grpc.CodeGenerator.compile_protos(output_path: "custom_output", http_transcoding_enabled: false)

  """
  def compile_protos(opts \\ []) do
    include_path = "#{File.cwd!()}/priv/protos"
    output_path = Keyword.get(opts, :output_path, "#{File.cwd!()}/priv/protos/modules")
    transcoding_enabled? = Keyword.get(opts, :http_transcoding_enabled, true)

    {grpc_generator_plugin, handler_generator_plugin} =
      if transcoding_enabled? do
        {ProtobufGenerate.Plugins.GRPCWithOptions,
         Sidecar.GRPC.Generators.HandlerTranscodingGenerator}
      else
        {ProtobufGenerate.Plugins.GRPC, Sidecar.GRPC.Generators.HandlerGenerator}
      end

    user_defined_proto_files =
      list_files_with_extension(include_path, ".proto")
      |> Enum.join(" ")

    protoc_options = [
      "--include-path=#{include_path}",
      "--include-path=#{File.cwd!()}/priv/protos/google/protobuf",
      "--include-path=#{File.cwd!()}/priv/protos/google/api",
      "--generate-descriptors=true",
      "--output-path=#{output_path}",
      "--plugins=#{grpc_generator_plugin}",
      "--plugins=#{handler_generator_plugin}",
      "--plugins=Sidecar.GRPC.Generators.ServiceGenerator",
      "--plugins=Sidecar.GRPC.Generators.ServiceResolverGenerator",
      "--plugins=Sidecar.Grpc.Generators.ReflectionServerGenerator",
      "#{include_path}/#{user_defined_proto_files}"
    ]

    _ = Generate.run(protoc_options)
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
  def load_modules(opts) do
    path = Keyword.get(opts, :output_path, "#{File.cwd!()}/priv/protos/modules")

    user_defined_modules_files = list_files_with_extension(path, ".pb.ex")

    Enum.map(user_defined_modules_files, fn file ->
      full_path = Path.join(path, file)
      File.read!(full_path)
    end)
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
  def compile_modules(modules) when is_list(modules), do: Enum.each(modules, &do_compile/1)

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

  defp list_files_with_extension(directory, extension) do
    {:ok, files} = File.ls(directory)

    files
    |> Enum.filter(&String.ends_with?(&1, extension))
  end
end
