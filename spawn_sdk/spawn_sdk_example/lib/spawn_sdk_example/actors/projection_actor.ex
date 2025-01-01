defmodule SpawnSdkExample.Actors.ProjectionActor do
  use SpawnSdk.Actor, name: "ProjectionActor"

  require Logger

  alias Io.Eigr.Spawn.Example.MyState
  alias Example.ExampleState

  action("Clock", fn %Context{} = ctx, %MyState{} = payload ->
    Logger.info("[projection] Projection Actor Received Request. Context: #{inspect(ctx)}")

    new_value = ctx.state.value + payload.value

    Value.of()
    |> Value.state(%ExampleState{
      id: "id_01",
      value: new_value,
      data: %Example.ExampleState.Data{
        id: "data_id_01",
        test: "data_test"
      }
    })
  end)
end
