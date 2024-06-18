defmodule SpawnCli.Commands.Install do
  use DoIt.Command,
    name: "install",
    description: "Install Spawn Operator in Kubernetes cluster."

  @vsn "1.4.1"

  option(:kubeconfig, :string, "Load a Kubernetes kube config file.",
    alias: :k,
    default: "~/.kube/config"
  )

  option(:envconfig, :string, "Load a Kubernetes kube config from environment variable.",
    alias: :e,
    default: "KUBECONFIG"
  )

  option(:version, :string, "Install Operator with a specific version.",
    alias: :V,
    default: @vsn,
    allowed_values: [
      @vsn
    ]
  )

  def run(_, %{kubeconfig: kubeconfig} = _opts, _context) do
    IO.inspect(kubeconfig, label: "Installing Spawn using file: ")
  end
end
