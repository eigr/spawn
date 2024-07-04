defmodule SpawnCtl.Commands.New.Behavior do
  defprotocol Runtime do
    @spec prepare(struct(), String.t(), function()) :: any()
    def prepare(strategy, lang, callback_function)
  end
end
