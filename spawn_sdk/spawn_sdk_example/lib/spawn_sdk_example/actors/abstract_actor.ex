defmodule SpawnSdkExample.Actors.AbstractActor do
  use SpawnSdk.Actor,
    abstract: true,
    persistent: false,
    state_type: Io.Eigr.Spawn.Example.MyState

  require Logger
  alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

  @impl true
  def handle_command(
        {:sum, %MyBusinessMessage{value: value} = data},
        %Context{state: state} = ctx
      ) do
    Logger.info("Received Request: #{inspect(data)}. Context: #{inspect(ctx)}")

    new_value =
      if is_nil(state) do
        0 + value
      else
        (state.value || 0) + value
      end

    %Value{}
    |> Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
    |> Value.reply!()
  end
end
