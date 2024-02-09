defmodule SpawnCli.Commands.New do
  use DoIt.Command,
    name: "new",
    description: "Create new Spawn project with specific target language"

  require Logger

  option(:language, :string, "elixir",
    alias: :l,
    default: "elixir"
  )

  def run(_, %{language: language}, _context) do
    Logger.info("Creating project using #{language}")
  end
end
