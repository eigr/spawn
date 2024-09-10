defmodule Actors.Actor.Entity.Lifecycle.StreamConsumer do
  @moduledoc false
  use Broadway

  alias Broadway.Message
  alias Spawn.Utils.Nats
  alias Eigr.Functions.Protocol.Fact
  alias Google.Protobuf.Timestamp

  @type opts :: %{
          projection_pid: pid(),
          actor_name: String.t(),
          strict_ordering: boolean()
        }

  @spec start_link(opts :: opts()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    Broadway.start_link(
      __MODULE__,
      name: opts.actor_name,
      context: opts,
      producer: [
        module: {
          OffBroadway.Jetstream.Producer,
          connection_name: Nats.connection_name(),
          stream_name: opts.actor_name,
          consumer_name: opts.actor_name
        },
        concurrency: build_concurrency(opts)
      ],
      processors: [
        default: [concurrency: build_concurrency(opts)]
      ],
      batchers: [
        default: [
          concurrency: build_concurrency(opts),
          # Avoi big batches, micro batches is better
          batch_size: 10,
          batch_timeout: 2_000
        ]
      ]
    )
  end

  @spec handle_message(any(), Broadway.Message.t(), any()) :: Broadway.Message.t()
  def handle_message(_processor_name, message, _context) do
    message
    |> build_fact()
    |> Message.configure_ack(on_success: :term)
  end

  @spec handle_batch(any(), Broadway.Message.t(), any(), opts()) :: Broadway.Message.t()
  def handle_batch(_, messages, _, context) do
    GenServer.cast(context.projection_pid, {:process_projection_events, messages})

    messages
  end

  @spec build_fact(Broadway.Message.t()) :: Broadway.Message.t()
  defp build_fact(message) do
    # %Broadway.Message{data: "{\"ACTION\":\"KEY_ADDED\",\"KEY\":\"MYKEY\",\"VALUE\":\"MYVALUE\"}", metadata: %{headers: [], topic: "actors.mike"}, acknowledger: {OffBroadway.Jetstream.Acknowledger, #Reference<0.743380651.807927811.227242>, %{on_success: :term, reply_to: "$JS.ACK.newtest.projectionviewertest.1.11.11.1725657673932595345.21"}}, batcher: :default, batch_key: :default, batch_mode: :bulk, status: :ok}

    payload = message.data
    _headers = message.metadata.headers
    topic = message.metadata.topic
    time = DateTime.utc_now() |> DateTime.to_unix(:seconds)
    metadata = %{} |> Map.put("topic", topic)

    %Fact{
      uuid: UUID.uuid4(:hex),
      metadata: metadata,
      state: payload,
      timestamp: %Timestamp{seconds: time}
    }
  end

  # Projections are like long-lasting threads and therefore concurrency should be avoided
  # if the intention is to have some notion of ordering.
  defp build_concurrency(%{strict_ordering: true}), do: 1
  defp build_concurrency(%{strict_ordering: false}), do: 15
end
