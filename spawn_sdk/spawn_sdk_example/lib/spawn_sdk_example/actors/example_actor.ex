defmodule SpawnSdkExample.Actors.ExampleActor do
  use SpawnSdk.Actor, name: "ExampleActor"

  require Logger

  alias Example.ExampleState
  alias Example.ValuePayload
  alias Example.SumResponse

  @doc """
  How to invoke this actor with SDK, based on the package: `example.actors`

  ## Examples

      iex> Example.Actors.ExampleActor.sum(%Example.ValuePayload{value: 10})
      {:ok, %Example.SumResponse{value: 10}}
  """
  action("Sum", fn %Context{state: state} = ctx, %ValuePayload{value: value} = data ->
    Logger.info("[Example] Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value = state.value + value

    Value.of()
    |> Value.state(%ExampleState{value: new_value})
    |> Value.response(%SumResponse{value: new_value})
  end)
end
