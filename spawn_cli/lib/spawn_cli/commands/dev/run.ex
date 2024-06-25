defmodule SpawnCli.Commands.Dev.Run do
  use DoIt.Command,
    name: "run",
    description: "Run Spawn proxy in dev mode."

  option(:actorsystem, :string, "Defines the name of the ActorSystem.",
    alias: :s,
    default: "spawn-system",
    keep: false
  )

  option(:actorhost, :string, "Defines the name of the ActorHost.",
    alias: :h,
    keep: false
  )

  def run(_, %{actorsystem: actorsystem, actorhost: actorhost} = opts, _context) do
    IO.inspect(opts, label: "Creating project using program language: ")
  end
end
