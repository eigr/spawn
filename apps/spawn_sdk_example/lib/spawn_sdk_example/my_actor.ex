defmodule SpawnSdkExample.MyActor do
  use SpawnSdk.Actor,
    name: "joe",
    persistent: false,
    state_type: Io.Eigr.Spawn.Example.MyState,
    deactivate_timeout: 5_000,
    snapshot_timeout: 2_000

  require Logger
  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  @impl true
  def handle_command({:sum, %MyBusinessMessage{} = data}, ctx) do
    Logger.info("Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")
    {:ok, %Value{}}
  end
end
