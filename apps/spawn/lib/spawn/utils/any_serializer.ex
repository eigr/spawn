defmodule Spawn.Utils.AnySerializer do
  alias Google.Protobuf.Any

  def unpack_any_bin(bin),
    do:
      Any.decode(bin)
      |> unpack_unknown()

  def unpack_unknown(any) do
    package_name =
      any.type_url
      |> String.replace("type.googleapis.com/", "")
      |> String.split(".")
      |> Enum.map(&upcase_first(&1))
      |> Enum.join(".")
      |> then(fn package -> Enum.join(["Elixir", package], ".") end)

    any_unpack!(any, String.to_existing_atom(package_name))
  end

  def any_pack!(record) do
    Any.new(
      type_url: get_type_url(record.__struct__),
      value: apply(record.__struct__, :encode, [record])
    )
  end

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
           do: list |> Enum.map(&String.downcase(&1)) |> Enum.join(".")

    type_name = parts |> List.last()

    "type.googleapis.com/#{package_name}.#{type_name}"
  end

  defp upcase_first(<<first::utf8, rest::binary>>), do: String.upcase(<<first::utf8>>) <> rest
end
