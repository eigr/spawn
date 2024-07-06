defmodule SpawnCtl.Commands.Install.Behavior do
  @moduledoc false
  defprotocol Runtime do
    @spec install(struct(), function()) :: any()
    def install(strategy, callback_function)
  end
end
