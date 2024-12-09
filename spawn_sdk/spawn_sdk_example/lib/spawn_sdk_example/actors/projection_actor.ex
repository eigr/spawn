defmodule SpawnSdkExample.Actors.ProjectionActor do
  use SpawnSdk.Actor,
    name: "projection_actor",
    kind: :projection,
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 60_000,
    snapshot_timeout: 10_000,
    subjects: [
      {"ClockActor", "SecondClock"},
      {"ClockActor", "Clock"}
    ]

  require Logger

  alias Io.Eigr.Spawn.Example.MyState

  # MyState { count: number, owner_id: string }
  # MyViewResponse { owner_id: string, points: number }
  # MyViewParams { owner_id: string }

  view name: "MyCreaturePoints",
    query: """
    SELECT owner_id, SUM(count) AS points
    FROM @state
    GROUP BY owner_id
    """,
    params_type: MyViewParams,
    response_type: MyViewResponse

  action("SecondClock", fn %Context{} = ctx, %MyState{} = payload ->
    Logger.info("[projection] Projection Actor Received Request. Context: #{inspect(ctx)}")

    value = payload.value
    new_value = (value || 0) + (Map.get(ctx.state || %{}, :value) || 0)

    {:ok, response} = Projection.lookup(ctx, "MyCreaturePoints", %MyViewParams{owner_id: ctx.owner_id})

    Value.of()
    |> Value.state(%MyState{value: new_value})
  end)
end
