defmodule ActivatorAPI.API.Generator do
  @moduledoc false
  require Logger
  alias Protobuf.Protoc.Generator.Message, as: MessageGenerator
  alias Protobuf.Protoc.Generator.Enum, as: EnumGenerator
  alias Protobuf.Protoc.Generator.Service, as: ServiceGenerator
  alias Protobuf.Protoc.Generator.Extension, as: ExtensionGenerator

  @locals_without_parens [field: 2, field: 3, oneof: 2, rpc: 3, extend: 4, extensions: 1]

  @spec generate_content(Context.t(), Google.Protobuf.FileDescriptorProto.t()) :: String.t()
  def generate_content(ctx, desc) do
    ctx = %{
      ctx
      | package: desc.package || "",
        syntax: syntax(desc.syntax),
        dep_type_mapping: get_dep_type_mapping(ctx, desc.dependency, desc.name)
    }

    ctx = Map.put(ctx, :module_prefix, ctx.package || "")
    ctx = Protobuf.Protoc.Context.custom_file_options_from_file_desc(ctx, desc)
    {enums, msgs} = MessageGenerator.generate_list(ctx, desc.message_type)

    list =
      enums ++
        Enum.map(desc.enum_type, fn d -> EnumGenerator.generate(ctx, d) end) ++
        msgs ++
        if Enum.member?(ctx.plugins, "grpc") do
          Enum.map(desc.service, fn d -> ServiceGenerator.generate(ctx, d) end)
        end

    # TODO Verify get_nested_extensions(ctx, desc.message_type)/2 error
    # nested_extensions =
    #   ExtensionGenerator.get_nested_extensions(ctx, desc.message_type)
    #   |> Enum.reverse()

    # list = list ++ [ExtensionGenerator.generate(ctx, desc, nested_extensions)]

    list
    |> List.flatten()
    |> Enum.filter(&(!is_nil(&1)))
    |> Enum.map(fn {_, v} -> v end)
    |> Enum.join("\n")
    |> format_code()
  end

  @doc false
  def get_dep_pkgs(%{pkg_mapping: mapping, package: pkg}, deps) do
    pkgs = deps |> Enum.map(fn dep -> mapping[dep] end)
    pkgs = if pkg && byte_size(pkg) > 0, do: [pkg | pkgs], else: pkgs
    Enum.sort(pkgs, &(byte_size(&2) <= byte_size(&1)))
  end

  def get_dep_type_mapping(%{global_type_mapping: global_mapping}, deps, file_name) do
    mapping =
      Enum.reduce(deps, %{}, fn dep, acc ->
        Map.merge(acc, global_mapping[dep])
      end)

    Map.merge(mapping, global_mapping[file_name])
  end

  defp syntax("proto3"), do: :proto3
  defp syntax(_), do: :proto2

  def format_code(code) do
    formatted =
      if Code.ensure_loaded?(Code) && function_exported?(Code, :format_string!, 2) do
        code
        |> Code.format_string!(locals_without_parens: @locals_without_parens)
        |> IO.iodata_to_binary()
      else
        code
      end

    if formatted == "" do
      formatted
    else
      formatted <> "\n"
    end
  end
end
