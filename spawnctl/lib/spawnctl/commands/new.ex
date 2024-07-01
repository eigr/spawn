defmodule SpawnCtl.Commands.New do
  use DoIt.Command,
    name: "new",
    description: "Create new Spawn project with specific target language."

  subcommand(SpawnCtl.Commands.New.Dart)
  subcommand(SpawnCtl.Commands.New.Elixir)
  subcommand(SpawnCtl.Commands.New.Go)
  subcommand(SpawnCtl.Commands.New.Java)
  subcommand(SpawnCtl.Commands.New.Node)
  subcommand(SpawnCtl.Commands.New.Python)
  subcommand(SpawnCtl.Commands.New.Rust)
end
