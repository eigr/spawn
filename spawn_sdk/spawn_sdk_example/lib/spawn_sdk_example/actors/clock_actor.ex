defmodule SpawnSdkExample.Actors.ClockActor do
  use SpawnSdk.Actor,
    name: "ClockActor",
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 15_000

  require Logger

  alias Io.Eigr.Spawn.Example.MyState

  action("Clock", [timer: 10_000], fn %Context{state: state} = ctx ->
    Logger.info("[clock] Clock Actor Received Request. Context: #{inspect(ctx)}")

    new_value = if is_nil(state), do: 0, else: state.value + 1
    new_state = MyState.new(value: new_value)

    Value.of()
    |> Value.state(new_state)
    |> Value.noreply!()
  end)

  action("SecondClock", [timer: 10_000], &second_clock/1)

  defp second_clock(%Context{state: state} = ctx) do
    Logger.info("[SECOND_CLOCK] Second Actor Received Request. Context: #{inspect(ctx)}")

    new_value = if is_nil(state), do: 0, else: state.value + 1
    new_state = MyState.new(value: new_value)

    Value.of()
    |> Value.state(new_state)
    |> Value.noreply!()
  end

  action("test", fn ->
    Logger.info("[TEST] Test Actor Received Request.")
    Value.of()
  end)
end
