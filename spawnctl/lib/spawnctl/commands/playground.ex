defmodule SpawnCtl.Commands.Playground do
  @moduledoc false
  use DoIt.Command,
    name: "playground",
    description: "Install and run a complete Spawn tutorial."

  subcommand(SpawnCtl.Commands.Playground.New)
end
