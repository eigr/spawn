defmodule SpawnSdkExample.Actors.PubSubActor do
  use SpawnSdk.Actor,
    name: "pubsub_actor",
    kind: :named,
    channels: [
      "test.pubsub.topic",
      {"test.pubsub.direct", "receive_direct"}
    ],
    deactivate_timeout: 60_000,
    state_type: Io.Eigr.Spawn.Example.MyState

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  defact publish(_, _ctx) do
    Logger.info("[Pubsub Actor] Published to my own topics")

    Value.of()
    |> Value.broadcast(Broadcast.to("test.pubsub.topic", %MyBusinessMessage{value: 1}))
  end

  defact publish_direct(_, _ctx) do
    Logger.info("[Pubsub Actor] Published to my own direct topic")

    Value.of()
    |> Value.broadcast(Broadcast.to("test.pubsub.direct", %MyBusinessMessage{value: 1}))
  end

  defact receive(%MyBusinessMessage{value: value} = data, %Context{state: state} = ctx) do
    Logger.info("[Pubsub Actor] Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value =
      if is_nil(state) do
        0 + value
      else
        (state.value || 0) + value
      end

    result = %MyBusinessMessage{value: new_value}
    new_state = %MyState{value: new_value}

    Value.of()
    |> Value.value(result)
    |> Value.state(new_state)
  end

  defact receive_direct(%MyBusinessMessage{value: value} = data, %Context{state: state} = ctx) do
    Logger.info(
      "[Pubsub Actor] Received Direct Request: #{inspect(data)}. Context: #{inspect(ctx)}"
    )

    new_value =
      if is_nil(state) do
        0 + value
      else
        (state.value || 0) + value
      end

    result = %MyBusinessMessage{value: new_value}
    new_state = %MyState{value: new_value}

    Value.of()
    |> Value.value(result)
    |> Value.state(new_state)
  end
end
