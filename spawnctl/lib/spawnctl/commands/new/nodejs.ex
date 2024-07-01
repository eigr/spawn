defmodule SpawnCtl.Commands.New.Node do
  @moduledoc """
  """
  use DoIt.Command,
    name: "node",
    description: "Generate a Spawn NodeJS project."

  option(:actor_system, :string, "Defines the name of the ActorSystem.",
    alias: :s,
    default: "spawn-system",
    keep: false
  )

  argument(:name, :string, "Name of the project to be created.")

  def run(_, %{actor_system: actor_system} = _opts, _context) do
  end
end
