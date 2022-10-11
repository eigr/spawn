defmodule SpawnSdkExample.Actors.ClockActor do
  use SpawnSdk.Actor,
    name: "clock_actor",
    timers: [clock: 10_000],
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 86400000

  require Logger

  alias Io.Eigr.Spawn.Example.MyState

  @impl true
  def handle_command({:clock, _ignored_data}, %Context{state: state} = ctx) do
    Logger.info("Clock Actor Received Request. Context: #{inspect(ctx)}")

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
