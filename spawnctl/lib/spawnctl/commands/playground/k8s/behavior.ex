defmodule Spawnctl.Commands.Playground.K8s.Behavior do
  defprotocol Installer do
    @spec install(struct(), function()) :: any()
    def install(strategy, callback_function)
  end
end
