defmodule Activator.Codec.Base64 do
  @behaviour Activator.Codec

  alias Google.Protobuf.Any

  def encode(data) do
    {:ok, data}
  end

  @spec decode(any) :: {:error, any} | {:ok, any}
  def decode(data) when is_binary(data) do
    data =
      data
      |> Base.decode64!()
      |> :erlang.iolist_to_binary()
      |> Any.decode()

    {:ok, data}
  end

  def decode(_), do: {:error, "Error on try decode data. Data must be a binary type"}
end
