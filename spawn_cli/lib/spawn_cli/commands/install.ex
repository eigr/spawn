defmodule SpawnCli.Commands.Install do
  use DoIt.Command,
    name: "install",
    description: "Install Spawn Operator in Kubernetes cluster"

  require Logger

  option(:kubeconfig, :string, "~/.kube/config",
    alias: :k,
    default: "~/.kube/config"
  )

  def run(_, %{kubeconfig: kubeconfig}, _context) do
    Logger.info("Installing Spawn using #{kubeconfig} file...")
  end
end
