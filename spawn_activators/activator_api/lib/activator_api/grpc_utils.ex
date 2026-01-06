defmodule ActivatorAPI.GrpcUtils do
  @moduledoc false
  require Logger

  def get_http_rule(method_descriptor) do
    Logger.debug("MethodOptions HTTP Rules: #{inspect(method_descriptor)}")

    Google.Protobuf.MethodOptions.get_extension(
      method_descriptor.options,
      Google.Api.PbExtension,
      :http
    )
  end

  def get_type_url(type) do
    parts =
      type
      |> to_string
      |> String.replace("Elixir.", "")
      |> String.split(".")

    package_name =
      with {_, list} <- parts |> List.pop_at(-1),
           do: list |> Stream.map(&String.downcase(&1)) |> Enum.join(".")

    type_name = parts |> List.last()
    "type.googleapis.com/#{package_name}.#{type_name}"
  end

  def compile(file) do
    Code.compile_string(file)
  rescue
    error in UndefinedFunctionError ->
      Logger.error("Error in Module definition. Make sure the service name is correct")
      raise error

    error ->
      Logger.error("Error during Service compilation phase #{inspect(error)}")
  end

  def normalize_service_name(name) do
    name
    |> String.split(".")
    |> Stream.map(&Macro.camelize(&1))
    |> Enum.join(".")
  end

  def normalize_method_name(name), do: Macro.underscore(name)

  def get_module(filename, bindings \\ []), do: EEx.eval_file(filename, bindings)
end
