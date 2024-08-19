defmodule SpawnCtl do
  @moduledoc """
  Documentation for `SpawnCli`.

  """
  use DoIt.MainCommand,
    description: "Spawn CLI Tool",
    version: "1.1.2"

  command(SpawnCtl.Commands.Apply)
  command(SpawnCtl.Commands.Config)
  command(SpawnCtl.Commands.Dev)
  command(SpawnCtl.Commands.Install)
  command(SpawnCtl.Commands.New)
  command(SpawnCtl.Commands.Playground)
end
