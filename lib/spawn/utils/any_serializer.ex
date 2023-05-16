defmodule Spawn.Utils.AnySerializer do
  @moduledoc """
  `AnySerializer` is responsible for serializing the protobuf type Any to Elixir
  structures and vice versa.
  """

  alias Google.Protobuf.Any
  alias Eigr.Functions.Protocol.JSONType

  import Spawn.Utils.Common, only: [to_existing_atom_or_new: 1]

  def unpack_any_bin(bin),
    do:
      Any.decode(bin)
      |> unpack_unknown()

  def unpack_unknown({:value, any}), do: unpack_unknown(any)
  def unpack_unknown({:noop, any}), do: unpack_unknown(any)

  def unpack_unknown(%{type_url: type_url} = any) do
    package_name =
      type_url
      |> String.replace("type.googleapis.com/", "")
      |> String.split(".")
      |> Enum.map_join(".", &upcase_first/1)
      |> then(fn package -> Enum.join(["Elixir", package], ".") end)

    any_unpack!(any, to_existing_atom_or_new(package_name))
    |> maybe_unpack_json!
  end

  def unpack_unknown(_), do: nil

  defp maybe_unpack_json!(%JSONType{} = json) do
    Jason.decode!(json.content, keys: :atoms)
  end

  defp maybe_unpack_json!(any_unpacked), do: any_unpacked

  def json_any_pack!(map) do
    %JSONType{content: Jason.encode!(map)}
    |> any_pack!()
  end

  def pack_all_to_any(nil, _state_type), do: {:ok, nil}
  def pack_all_to_any(record, :json) when is_map(record), do: {:ok, json_any_pack!(record)}
  def pack_all_to_any(%Any{} = record, _state_type), do: {:ok, record}
  def pack_all_to_any(record, state_type), do: any_pack(record, state_type)

  def any_pack!(nil), do: nil

  def any_pack!(%Any{} = record), do: record

  def any_pack!(record) when is_struct(record) do
    %Any{
      type_url: get_type_url(record.__struct__),
      value: apply(record.__struct__, :encode, [record])
    }
  end

  def any_pack!(_), do: raise(ArgumentError, "wrong_action_output")

  def any_unpack!(any_record, builder) do
    builder.decode(any_record.value)
  end

  defp get_type_url(type) do
    parts =
      type
      |> to_string
      |> String.replace("Elixir.", "")
      |> String.split(".")

    package_name =
      with {_, list} <- parts |> List.pop_at(-1),
           do: Enum.map_join(list, ".", &String.downcase/1)

    type_name = parts |> List.last()

    "type.googleapis.com/#{package_name}.#{type_name}"
  end

  defp upcase_first(<<first::utf8, rest::binary>>), do: String.upcase(<<first::utf8>>) <> rest

  defp any_pack(record, state_type) when is_struct(record) do
    {:ok,
     %Any{
       type_url: get_type_url(state_type),
       value: apply(state_type, :encode, [record])
     }}
  end

  defp any_pack(_, _), do: {:error, :invalid_state}
end
