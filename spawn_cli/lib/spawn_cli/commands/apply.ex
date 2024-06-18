defmodule SpawnCli.Commands.Apply do
  use DoIt.Command,
    name: "apply",
    description: "Apply Actors resources in Kubernetes cluster"

  require Logger

  option(:all, :string, "all",
    alias: :A,
    default: "default"
  )

  option(:actorsystem, :string, "actorsystem",
    alias: :S,
    default: "spawn-system"
  )

  option(:actorhost, :string, "actorhost",
    alias: :S,
    keep: false
  )

  option(:context, :string, "context",
    alias: :c,
    default: "default"
  )

  option(:kubeconfig, :string, "~/.kube/config",
    alias: :k,
    default: "~/.kube/config"
  )

  def run(_, %{kubeconfig: kubeconfig}, context) do
    Logger.info("Installing Spawn with context #{context} file...")
    Logger.info("Apply Spawn manifest using #{kubeconfig} file...")
  end
end
