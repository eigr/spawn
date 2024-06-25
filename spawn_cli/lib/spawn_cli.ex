defmodule SpawnCli do
  @moduledoc """
  Documentation for `SpawnCli`.

  """
  use DoIt.MainCommand,
    description: "Spawn CLI Tool",
    version: "1.1.2"

  command(SpawnCli.Commands.Install)
  command(SpawnCli.Commands.New)
  command(SpawnCli.Commands.Apply)
  command(SpawnCli.Commands.Dev)
end
