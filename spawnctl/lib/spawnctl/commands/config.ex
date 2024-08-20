defmodule SpawnCtl.Commands.Config do
  @moduledoc false
  use DoIt.Command,
    name: "config",
    description: "Configure Spawn applications."

  subcommand(SpawnCtl.Commands.Config.Host)
  subcommand(SpawnCtl.Commands.Config.System)
end
