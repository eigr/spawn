defmodule SpawnCtl do
  @moduledoc """
  Documentation for `SpawnCli`.

  """
  use DoIt.MainCommand,
    description: "Spawn CLI Tool",
    version: "2.0.0-RC1"

  command(SpawnCtl.Commands.Apply)
  command(SpawnCtl.Commands.Config)
  command(SpawnCtl.Commands.Dev)
  command(SpawnCtl.Commands.Install)
  command(SpawnCtl.Commands.New)
  command(SpawnCtl.Commands.Playground)
end
