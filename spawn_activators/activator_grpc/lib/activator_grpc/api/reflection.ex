defmodule ActivatorGRPC.API.Reflection do
  @moduledoc false
  require Logger

  alias ActivatorGRPC.API.Generator

  def prepare(file_descriptor) do
    ctx =
      %Protobuf.Protoc.Context{gen_descriptors?: true, plugins: ["grpc"]}
      |> find_types(file_descriptor)

    file_descriptor
    |> Stream.map(fn desc ->
      {desc.name, Generator.generate_content(ctx, desc)}
    end)
    |> Enum.to_list()
  end

  @doc false
  def find_types(ctx, descs) do
    find_types(ctx, descs, %{})
  end

  @doc false
  def find_types(ctx, [], acc) do
    %{ctx | global_type_mapping: acc}
  end

  def find_types(ctx, [desc | t], acc) do
    types = find_types_in_proto(desc)
    find_types(ctx, t, Map.put(acc, desc.name, types))
  end

  @doc false
  def find_types_in_proto(%Google.Protobuf.FileDescriptorProto{} = desc) do
    desc_ctx = %Protobuf.Protoc.Context{
      package: desc.package,
      namespace: []
    }

    ctx = %{desc_ctx | module_prefix: desc_ctx.package || ""}

    %{}
    |> find_types_in_proto(ctx, desc.message_type)
    |> find_types_in_proto(ctx, desc.enum_type)
  end

  defp find_types_in_proto(types, ctx, descs) when is_list(descs) do
    Enum.reduce(descs, types, fn desc, acc ->
      find_types_in_proto(acc, ctx, desc)
    end)
  end

  defp find_types_in_proto(types, ctx, %Google.Protobuf.DescriptorProto{name: name} = desc) do
    new_ctx = append_ns(ctx, name)

    types
    |> update_types(ctx, name)
    |> find_types_in_proto(new_ctx, desc.enum_type)
    |> find_types_in_proto(new_ctx, desc.nested_type)
  end

  defp find_types_in_proto(types, ctx, %Google.Protobuf.EnumDescriptorProto{name: name}) do
    update_types(types, ctx, name)
  end

  defp append_ns(%{namespace: ns} = ctx, name) do
    new_ns = ns ++ [name]
    Map.put(ctx, :namespace, new_ns)
  end

  defp update_types(types, %{namespace: ns, package: pkg, module_prefix: prefix}, name) do
    type_name =
      join_names(prefix || pkg, ns, name)
      |> normalize_type_name()

    Map.put(types, "." <> join_names(pkg, ns, name), %{type_name: type_name})
  end

  defp join_names(pkg, ns, name) do
    ns_str = Enum.join(ns, ".")

    [pkg, ns_str, name]
    |> Enum.filter(&(&1 && &1 != ""))
    |> Enum.join(".")
  end

  defp normalize_type_name(name) do
    name
    |> String.split(".")
    |> Enum.map_join(".", &trans_name/1)
  end

  defp trans_name(name) do
    Macro.camelize(name)
  end
end
