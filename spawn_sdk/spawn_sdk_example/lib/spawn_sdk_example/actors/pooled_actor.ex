defmodule SpawnSdkExample.Actors.PooledActor do
  use SpawnSdk.Actor,
    name: "pooled_actor",
    kind: :pooled,
    deactivate_timeout: 240_000,
    min_pool_size: 1,
    max_pool_size: 10,
    stateful: false

  require Logger

  defact ping(_data, %Context{} = ctx) do
    Logger.info("Received Request. Context: #{inspect(ctx)}")

    Value.of()
    |> Value.void()
  end
end
