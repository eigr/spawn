defmodule Activator.Codec.CloudEvent do
  @behaviour Activator.Codec

  alias Google.Protobuf.Any
  alias Io.Cloudevents.V1.CloudEvent, as: CloudEventType

  def encode(data) do
    {:ok, data}
  end

  @spec decode(any) :: {:error, any} | {:ok, any}
  def decode(data) when is_binary(data) do
    case CloudEventType.decode(data) do
      %Io.Cloudevents.V1.CloudEvent{
        attributes: _attributes,
        data: {:binary_data, event_data},
        id: _id,
        source: _source,
        spec_version: _spec,
        type: _type
      } = _decoded_data ->
        {:ok, Any.decode(event_data)}

      error ->
        {:error, "Error on try decode data. Error #{inspect(error)}"}
    end
  end

  def decode(_), do: {:error, "Error on try decode data. Data must be a binary type"}
end
