defmodule Spawnctl.Runtimes.Behaviors.WindowsRuntime do
  @moduledoc """
  Windows implementation of Commands
  """
  defmodule New do
    alias Spawnctl.Runtimes.Behaviors.WindowsRuntime.New, as: WindowsNewCommand
    import SpawnCtl.Util, only: [extract_tar_gz: 1]

    defstruct opts: %{}

    defimpl SpawnCtl.Commands.New.Behavior.Runtime, for: __MODULE__ do
      @impl true
      def prepare(%WindowsNewCommand{} = _strategy, _lang, callback)
          when is_function(callback, 1) do
        raise ArgumentError, "Not implemented"
      end
    end
  end
end
