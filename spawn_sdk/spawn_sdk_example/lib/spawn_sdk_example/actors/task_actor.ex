defmodule SpawnSdkExample.Actors.TaskActor do
  use SpawnSdk.Actor,
    name: "TaskActor",
    state_type: Io.Eigr.Spawn.Example.MyState,
    kind: :task,
    deactivate_timeout: 60_000,
    snapshot_timeout: 2_000

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  action("Sum", fn %Context{state: state} = ctx, %MyBusinessMessage{value: value} = data ->
    Logger.info("[task] Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value =
      if is_nil(state) do
        0 + value
      else
        (state.value || 0) + value
      end

    response = %MyBusinessMessage{value: new_value}

    %Value{}
    |> Value.of(response, %MyState{value: new_value})
    |> Value.reply!()
  end)
end
