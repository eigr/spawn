defmodule SpawnSdkExample.Actors.PooledActor do
  use SpawnSdk.Actor,
    name: "pooled_actor",
    kind: :pooled,
    stateful: false

  require Logger

  defact ping(_data, %Context{} = ctx) do
    Logger.info("Received Request. Context: #{inspect(ctx)}")

    Value.of()
    |> Value.void()
  end
end
