defmodule Spawn.Util do
  alias Google.Protobuf.Any

  def to_any(msg, input_type),
    do:
      Any.new(
        type_url: get_type_url(input_type),
        value: input_type.encode(msg)
      )

  def to_module(%Any{value: bin}, output_mod), do: output_mod.decode(bin)

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
end
