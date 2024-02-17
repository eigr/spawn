defmodule Sidecar.Grpc.CodeGenerator do
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
         Sidecar.Grpc.Generators.HandlerTranscodingGenerator}
      else
        {ProtobufGenerate.Plugins.GRPC, Sidecar.Grpc.Generators.HandlerGenerator}
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
      # "--plugins=Sidecar.Grpc.Generators.ServiceGenerator",
      "#{include_path}/#{user_defined_proto_files}"
    ]

    _ = Generate.run(protoc_options)
  end

  @doc """
  Compiles an Elixir module generated from Protobuf files and returns the compiled code.

  ### Parameters:

  - `module` - The String of Elixir module code generated from Protobuf files.

  ### Returns:

  The compiled Elixir code.

  ### Example:

  ```elixir
  module_code = Sidecar.Grpc.CodeGenerator.compile_module(generated_code)

  Raises:

  Raises an error if there are issues during the compilation process.

  """
  def compile_module(module), do: do_compile(module)

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

  defp normalize_service_name(name) do
    name
    |> String.split(".")
    |> Stream.map(&Macro.camelize(&1))
    |> Enum.join(".")
  end

  defp normalize_method_name(name), do: Macro.underscore(name)

  defp get_module(filename, bindings \\ []), do: EEx.eval_file(filename, bindings)
end
