defmodule SpawnCtl.Commands.New.Go do
  @moduledoc """
  """
  use DoIt.Command,
    name: "go",
    description: "Generate a Spawn Golang project."

  option(:actor_system, :string, "Defines the name of the ActorSystem.",
    alias: :s,
    default: "spawn-system",
    keep: false
  )

  argument(:name, :string, "Name of the project to be created.")

  def run(_, %{actor_system: actor_system} = _opts, _context) do
  end
end
