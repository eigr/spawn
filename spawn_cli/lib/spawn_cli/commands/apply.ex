defmodule SpawnCli.Commands.Apply do
  use DoIt.Command,
    name: "apply",
    description: "Apply Actors resources in Kubernetes cluster."

  option(:context, :string, "Apply manifest on specified Kubernetes Context.",
    alias: :c,
    default: "default"
  )

  option(:dryrun, :string, "Flag to preview the object that would be sent to your cluster, without really submitting it.",
    alias: :d,
    default: "client"
  )

  option(:file, :string, "Applies only the specified resource file or path (does not try to find files automatically).",
    alias: :f,
    default: ".k8s"
  )

  option(:kubeconfig, :string, "Load a Kubernetes kube config file.",
    alias: :k,
    default: "~/.kube/config"
  )

  option(:namespace, :string, "Apply manifests no specified Kubernetes namespace.",
    alias: :n,
    default: "default"
  )

  def run(_, %{kubeconfig: kubeconfig }= _opts, context) do
    IO.inspect(context, label: "Installing Spawn with context file: ")
    IO.inspect(kubeconfig, label: "Apply Spawn manifest using file: ")
  end
end
