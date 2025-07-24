defmodule Actors.Actor.Entity.Lifecycle.StreamConsumer do
  @moduledoc false
  use Broadway

  alias Broadway.Message
  alias Spawn.Utils.Nats
  alias Spawn.Fact
  alias Google.Protobuf.Timestamp
  alias Sidecar.GracefulShutdown

  @type fact :: %Fact{}

  @type opts :: %{
          projection_pid: pid(),
          actor_name: String.t(),
          strict_ordering: boolean()
        }

  @spec start_link(opts :: opts()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    Broadway.start_link(
      __MODULE__,
      # there will be not a lot so probably fine to convert to atom
      name: String.to_atom(opts.actor_name),
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

  @spec handle_message(any(), Message.t(), any()) :: Message.t()
  def handle_message(_processor_name, message, _context) do
    if GracefulShutdown.running?() do
      message
      |> build_fact()
      |> Message.configure_ack(on_success: :term)
    else
      message
      |> Message.failed("Failed to deliver because app is draining")
    end
  end

  @spec handle_batch(any(), Message.t(), any(), opts()) :: list(Message.t())
  def handle_batch(_, messages, _, context) do
    GenServer.cast(context.projection_pid, {:process_projection_events, messages})

    messages
  end

  @spec build_fact(Message.t()) :: Message.t()
  defp build_fact(message) do
    message
    |> Message.put_data(process_data(message))
  end

  @spec process_data(Message.t()) :: fact()
  defp process_data(message) do
    payload = message.data

    metadata =
      Enum.reduce(message.metadata.headers, %{}, fn {key, value}, acc ->
        Map.put(acc, key, value)
      end)
      |> Map.put("topic", message.metadata.topic)

    time = DateTime.utc_now() |> DateTime.to_unix(:seconds)

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
  defp build_concurrency(%{strict_ordering: false}), do: System.schedulers_online()
end
