defmodule SpawnCtl do
  @moduledoc """
  Documentation for `SpawnCli`.

  """
  use DoIt.MainCommand,
    description: "Spawn CLI Tool",
    version: "1.1.2"

  command(SpawnCtl.Commands.Install)
  command(SpawnCtl.Commands.New)
  command(SpawnCtl.Commands.Apply)
  command(SpawnCtl.Commands.Dev)
end
