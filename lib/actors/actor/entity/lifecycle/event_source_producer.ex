defmodule Actors.Actor.Entity.Lifecycle.EventSourceProducer do
  @moduledoc false
  use Broadway

  alias Broadway.Message
  alias Spawn.Utils.Nats

  @type opts :: %{
          projection_pid: pid(),
          actor_name: String.t()
        }

  @spec start_link(opts :: opts()) :: :ignore | {:error, any} | {:ok, pid}
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
        # Projects are like long-lasting threads and therefore concurrency should be avoided
        # if the intention is to have some notion of ordering.
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 1]
      ],
      batchers: [
        default: [
          concurrency: 1,
          batch_size: 10_000,
          batch_timeout: 2_000
        ]
      ]
    )
  end

  @spec handle_message(any(), Broadway.Message.t(), any()) :: Broadway.Message.t()
  def handle_message(_processor_name, message, _context) do
    message
    |> Message.configure_ack(on_success: :term)
  end

  @spec handle_batch(any(), Broadway.Message.t(), any(), opts()) :: Broadway.Message.t()
  def handle_batch(_, messages, _, context) do
    GenServer.cast(context.projection_pid, {:process_projection_events, messages})

    messages
  end
end
