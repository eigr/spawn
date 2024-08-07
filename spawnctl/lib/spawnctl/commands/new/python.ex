defmodule SpawnCtl.Commands.New.Python do
  @moduledoc """
  """
  use DoIt.Command,
    name: "python",
    description: "Generate a Spawn Python project."

  option(:actor_system, :string, "Defines the name of the ActorSystem.",
    alias: :s,
    default: "spawn-system",
    keep: false
  )

  argument(:name, :string, "Name of the project to be created.")

  def run(_, %{actor_system: actor_system} = _opts, _context) do
  end
end
