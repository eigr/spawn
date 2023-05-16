defmodule SpawnSdkExample.Actors.JsonActor do
  use SpawnSdk.Actor,
    name: "json",
    state_type: :json,
    deactivate_timeout: 60_000,
    snapshot_timeout: 2_000

  defmodule State do
    @derive {Jason.Encoder, only: [:value]}
    defstruct [:value, :should_ignore]
  end

  defact sum(%{value: value}, %Context{state: state} = ctx) do
    new_value = (value || 0) + (state.value || 0)

    response = %{total_value: new_value}

    Value.of()
    |> Value.response(response)
    |> Value.state(%State{value: new_value, should_ignore: "ignore"})
  end
end
