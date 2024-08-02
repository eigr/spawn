defmodule SpawnCtl.Commands.Playground.New do
  @moduledoc """
  """
  use DoIt.Command,
    name: "new",
    description: "Create and run a new Spawn playground."

  alias SpawnCtl.Util.Emoji
  alias Spawnctl.Commands.Playground.K8s.Behavior.Installer
  alias Spawnctl.Commands.Playground.K8s.K3d.Install, as: K3dInstallCommand
  alias Spawnctl.Commands.Playground.K8s.Kind.Install, as: KindInstallCommand
  alias Spawnctl.Commands.Playground.K8s.Minikube.Install, as: MinikubeInstallCommand

  alias SpawnCtl.Commands.Install.Behavior.Runtime
  alias Spawnctl.Runtimes.Behaviors.K8sRuntime.Install, as: RuntimeInstallCommand

  import SpawnCtl.Util, only: [log: 3]

  @default_opts %{
    name: "spawn-playground",
    timeout: "5m"
  }

  @vsn "v1.4.1"

  option(:name, :string, "Defines the name of the Playground.",
    alias: :n,
    default: @default_opts.name
  )

  option(:timeout, :string, "Defines the timeout for execution of command.",
    alias: :t,
    default: @default_opts.timeout
  )

  option(:k8s_flavour, :string, "Defines the kubernetes provider.",
    alias: :k,
    allowed_values: [
      "k3d",
      "kind",
      "minikube"
    ]
  )

  def run(args, opts, context) do
    log(
      :info,
      Emoji.runner(),
      "Creating a new playground called #{opts.name}. This could be a real marathon..."
    )

    user_home = System.user_home!()
    kubecfg_default_dir = Path.join(user_home, ".kube")
    kubecfg_default_file = Path.join(kubecfg_default_dir, "config")

    opts
    |> install_k8s(args, context)
    |> install_operator(kubecfg_default_file, args, context)
    |> then(fn opt ->
      nil
    end)
  end

  defp install_k8s(%{k8s_flavour: "k3d"} = opts, _args, _context) do
    %K3dInstallCommand{opts: opts}
    |> Installer.install(fn out_opts -> out_opts end)
  end

  defp install_k8s(%{k8s_flavour: "kind"} = opts, _args, _context) do
    %KindInstallCommand{opts: opts}
    |> Installer.install(fn out_opts -> out_opts end)
  end

  defp install_k8s(%{k8s_flavour: "minikube"} = opts, _args, _context) do
    %MinikubeInstallCommand{opts: opts}
    |> Installer.install(fn out_opts -> out_opts end)
  end

  defp install_operator(%{k8s_flavour: "minikube", name: _name} = opts, kubecfg_default_file, _args, _context) do
    install_opts = %{
      context: "minikube",
      env_config: "none",
      kubeconfig: kubecfg_default_file,
      version: @vsn
    }

    %RuntimeInstallCommand{opts: install_opts, kubeconfig: kubecfg_default_file}
    |> Runtime.install(fn -> opts end)
  end

  defp install_operator(%{k8s_flavour: "k3d", name: name} = opts, kubecfg_default_file, _args, _context) do
    install_opts = %{
      context: "k3d-#{name}",
      env_config: "none",
      kubeconfig: kubecfg_default_file,
      version: @vsn
    }

    %RuntimeInstallCommand{opts: install_opts, kubeconfig: kubecfg_default_file}
    |> Runtime.install(fn -> opts end)
  end

  defp install_operator(%{k8s_flavour: _k8s_flavour, name: name} = opts, kubecfg_default_file, _args, _context) do
    install_opts = %{
      context: name,
      env_config: "none",
      kubeconfig: kubecfg_default_file,
      version: @vsn
    }

    %RuntimeInstallCommand{opts: install_opts, kubeconfig: kubecfg_default_file}
    |> Runtime.install(fn -> opts end)
  end
end
