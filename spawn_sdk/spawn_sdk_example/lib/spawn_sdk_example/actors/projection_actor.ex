defmodule SpawnSdkExample.Actors.ProjectionActor do
  use SpawnSdk.Actor, name: "ProjectionActor"

  require Logger

  alias Io.Eigr.Spawn.Example.MyState

  action("Clock", fn %Context{} = ctx, %MyState{} = payload ->
    Logger.info("[projection] Projection Actor Received Request. Context: #{inspect(ctx)}")

    value = payload.value
    new_value = (value || 0) + (Map.get(ctx.state || %{}, :value) || 0)

    Value.of()
    |> Value.state(%MyState{value: new_value})
  end)
end
