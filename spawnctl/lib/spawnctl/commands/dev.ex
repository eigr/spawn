defmodule SpawnCtl.Commands.Dev do
  use DoIt.Command,
    name: "dev",
    description: "Manages local development."

  subcommand(SpawnCtl.Commands.Dev.Run)
end
