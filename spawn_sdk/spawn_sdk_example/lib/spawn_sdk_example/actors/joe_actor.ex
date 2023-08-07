defmodule SpawnSdkExample.Actors.JoeActor do
  use SpawnSdk.Actor,
    name: "joe",
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 10_000,
    snapshot_timeout: 2_000

  require Logger

  alias Io.Eigr.Spawn.Example.{
    MyState,
    MyBusinessMessage
  }

  defact init(%Context{state: state} = ctx) do
    Logger.info("[joe] Received InitRequest. Context: #{inspect(ctx)}")

    new_state =
      if is_nil(state) do
        %MyState{value: 0}
      else
        state
      end

    %Value{}
    |> Value.state(new_state)
    |> Value.reply!()
  end

  defact sum(%MyBusinessMessage{value: value} = data, %Context{state: state} = ctx) do
    Logger.info("[joe] Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value =
      if is_nil(state) do
        0 + value
      else
        (state.value || 0) + value
      end

    response = %MyBusinessMessage{value: new_value}

    %Value{}
    |> Value.of(response, %MyState{value: new_value})
    |> Value.broadcast(Broadcast.to("external.channel", response))
    # |> Value.broadcast(Broadcast.to("liveview.channel", response))
    |> Value.reply!()
  end

  defact ping(_data, %Context{state: state} = ctx) do
    Logger.info("Received Request PING. Context: #{inspect(ctx)}")

    new_state =
      if is_nil(state) do
        %MyState{value: 0}
      else
        state
      end

    Value.of()
    |> Value.state(new_state)
    |> Value.noreply!()
  end
end
