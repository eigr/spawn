defmodule SpawnCli.Commands.New do
  use DoIt.Command,
    name: "new",
    description: "Create new Spawn project with specific target language."

  option(:actorsystem, :string, "Defines the name of the ActorSystem.",
    alias: :s,
    default: "spawn-system",
    keep: false
  )

  option(:actorhost, :string, "Defines the name of the ActorHost.",
    alias: :h,
    keep: false
  )

  option(:language, :string, "Defines the language and SDK to be used.",
    alias: :l,
    default: "elixir",
    allowed_values: [
      "dart",
      "elixir",
      "java-std",
      "java-springboot",
      "nodejs",
      "python"
    ]
  )

  argument(:name, :string, "Name of the project to be created.")

  def run(_, %{language: language} = _opts, _context) do
    IO.inspect(language, label: "Creating project using program language: ")
  end
end
