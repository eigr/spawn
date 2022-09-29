defmodule SpawnSdkExample.MyActor do
  use SpawnSdk.Actor,
    name: "jose",
    persistent: true,
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 30_000,
    snapshot_timeout: 2_000

  require Logger
  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  @impl true
  def handle_command(
        {:sum, %MyBusinessMessage{value: value} = data},
        %Context{state: state} = ctx
      ) do
    Logger.info("Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value = (state.value || 0) + value

    %Value{}
    |> Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
    |> Value.reply!()
  end
end
