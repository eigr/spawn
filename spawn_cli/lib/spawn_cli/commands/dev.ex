defmodule SpawnCli.Commands.Dev do
  use DoIt.Command,
    name: "dev",
    description: "Manages local development."

  subcommand(SpawnCli.Commands.Dev.Run)
end
