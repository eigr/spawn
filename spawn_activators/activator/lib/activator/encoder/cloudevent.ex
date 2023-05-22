defmodule Activator.Encoder.CloudEvent do
  @doc """
  `CloudEvent`
  """
  @behaviour Activator.Encoder

  alias Google.Protobuf.Any
  alias Io.Cloudevents.V1.CloudEvent

  def encode(data) do
    {:ok, data}
  end

  @spec decode(any) :: {:error, any} | {:ok, any}
  def decode(data) when is_binary(data) do
    case CloudEvent.decode(data) do
      %Io.Cloudevents.V1.CloudEvent{
        attributes: _attributes,
        data: {:binary_data, payload},
        id: id,
        source: source,
        spec_version: _spec,
        type: _type
      } = _decoded_data ->
        {:ok, source, id, Any.decode(payload)}

      error ->
        {:error, "Error on try decode data. Error #{inspect(error)}"}
    end
  end

  def decode(%CloudEvent{source: source, id: id, data: nil} = _data), do: {:ok, source, id, nil}

  def decode(%CloudEvent{source: source, id: id, data: {:binary_data, payload}} = _data),
    do: {:ok, source, id, Any.decode(payload)}

  def decode(_), do: {:error, "Error on try decode data. Data must be a binary type"}
end
