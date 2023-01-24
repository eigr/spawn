defmodule SpawnSdkExample.Actors.AbstractActor do
  use SpawnSdk.Actor,
    name: "abs_actor",
    kind: :abstract,
    deactivate_timeout: 60_000,
    state_type: Io.Eigr.Spawn.Example.MyState

  require Logger

  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  defact sum(%MyBusinessMessage{value: value} = data, %Context{state: state} = ctx) do
    Logger.info("[abstract] Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

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
    |> Value.effects(
      SideEffect.of()
      |> SideEffect.effect("joe", :sum, result)
    )
    |> Value.reply!()
  end
end
