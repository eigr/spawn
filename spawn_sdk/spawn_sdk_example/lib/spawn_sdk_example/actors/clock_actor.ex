defmodule SpawnSdkExample.Actors.ClockActor do
  use SpawnSdk.Actor,
    name: "clock_actor",
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 86_400_000

  require Logger

  alias Io.Eigr.Spawn.Example.MyState

  @set_timer 15_000
  defact clock(%Context{state: state} = ctx) do
    Logger.info("[clock] Clock Actor Received Request. Context: #{inspect(ctx)}")

    new_value = if is_nil(state), do: 0, else: state.value + 1
    new_state = MyState.new(value: new_value)

    Value.of()
    |> Value.state(new_state)
    |> Value.noreply!()
  end
end
