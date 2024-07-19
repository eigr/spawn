defmodule SpawnCtl.Commands.Playground.New do
  @moduledoc """
  """
  use DoIt.Command,
    name: "new",
    description: "Run a new Spawn playground."

  alias SpawnCtl.Util.Emoji

  import SpawnCtl.Util, only: [log: 3]

  @default_opts %{
    name: "spawn-playground",
  }

  option(:name, :string, "Defines the name of the Playground.",
    alias: :n,
    default: @default_opts.name
  )

  option(:k8s_flavour, :string, "Defines the kubernetes provider.",
    alias: :k,
    allowed_values: [
      "k3d",
      "kind",
      "minikube"
    ]
  )

  def run(args, opts, _context) do
  end
end
