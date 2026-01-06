defmodule Actors.Actor.Entity.Lifecycle.StreamConsumer do
  @moduledoc false
  use Gnat.Jetstream.PullConsumer

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Spawn.Utils.Nats
  alias Spawn.Fact
  alias Google.Protobuf.Timestamp
  alias Sidecar.GracefulShutdown
  alias Spawn.Actors.ActorSystem
  alias Spawn.Actors.Actor
  alias Spawn.Actors.ActorId
  alias Spawn.InvocationRequest

  @type fact :: %Fact{}

  @type opts :: %{
          projection_pid: pid(),
          actor_name: String.t(),
          strict_ordering: boolean()
        }

  def start_link(opts) do
    Gnat.Jetstream.PullConsumer.start_link(__MODULE__, opts,
      name: String.to_atom(opts.actor_name)
    )
  end

  @impl true
  def init(opts) do
    {:ok, opts,
     connection_name: Nats.connection_name(),
     stream_name: opts.actor_name,
     consumer_name: opts.actor_name}
  end

  def handle_message(message, state) do
    if GracefulShutdown.running?() do
      payload = message.body

      metadata =
        Enum.reduce(message.headers, %{}, fn {key, value}, acc ->
          Map.put(acc, key, value)
        end)
        |> Map.put("topic", message.topic)

      time = DateTime.utc_now() |> DateTime.to_unix(:second)

      fact = %Fact{
        uuid: UUID.uuid4(:hex),
        metadata: metadata,
        state: payload,
        timestamp: %Timestamp{seconds: time}
      }

      process_message(fact, state)

      {:ack, state}
    else
      {:nack, state}
    end
  end

  # Process a single message and invoke the actor
  defp process_message(%Fact{} = message, state) do
    actor_name = state.actor_name |> String.split("-") |> List.last()
    actor_settings = :persistent_term.get("actor-#{actor_name}")

    system_name = Map.get(message.metadata, "spawn-system")
    parent = Map.get(message.metadata, "actor-parent")
    name = Map.get(message.metadata, "actor-name")
    source_action = Map.get(message.metadata, "actor-action")

    action_metadata =
      case Map.get(message.metadata, "action-metadata") do
        nil -> %{}
        metadata -> Jason.decode!(metadata)
      end

    action =
      actor_settings.subjects
      |> Enum.find(fn subject -> subject.source_action == source_action end)
      |> Map.get(:action)

    invocation = %InvocationRequest{
      system: %ActorSystem{name: system_name},
      actor: %Actor{id: %ActorId{name: actor_name, system: system_name}},
      metadata: action_metadata,
      action_name: action,
      payload: {:value, Google.Protobuf.Any.decode(message.state)},
      caller: %ActorId{name: name, system: system_name, parent: parent}
    }

    # If this raises or throws, the error will be caught in handle_batch
    # and the message will be marked as failed for Broadway to retry
    {:ok, _response} = Actors.invoke(invocation, span_ctx: Tracer.current_span_ctx())
  end
end
