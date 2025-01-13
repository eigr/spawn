defmodule SpawnCtl.Commands.Install.Kubernetes do
  use DoIt.Command,
    name: "kubernetes",
    description: "Install k8s Orchestrator Runtime."

  @vsn "v2.0.0-RC4"

  alias SpawnCtl.Util.Emoji
  alias SpawnCtl.Commands.Install.Behavior.Runtime
  alias Spawnctl.Runtimes.Behaviors.K8sRuntime.Install, as: InstallCommand

  import SpawnCtl.Util, only: [log: 3]

  option(:kubeconfig, :string, "Load a Kubernetes kube config file.", alias: :k)

  option(:env_config, :string, "Load a Kubernetes kube config from environment variable.",
    alias: :e,
    default: "none"
  )

  option(:context, :string, "Apply manifest on specified Kubernetes Context.",
    alias: :c,
    default: "minikube"
  )

  option(:version, :string, "Install Operator with a specific version.",
    alias: :V,
    allowed_values: [
      @vsn,
      "1.4.2"
    ]
  )

  def run(_, %{kubeconfig: cfg, env_config: env} = opts, context) when not is_nil(cfg) do
    kubeconfig =
      if env == "none" && File.exists?(cfg) do
        cfg
      else
        kcfg = System.get_env(env)

        if not is_nil(kcfg) && File.exists?(kcfg) do
          kcfg
        else
          log(
            :error,
            Emoji.tired_face(),
            "You need to specify a valid kubeconfig file or kubeconfig environment variable. See options: [--kubeconfig, --env-config]"
          )

          help(context)
          System.stop(1)
        end
      end

    %InstallCommand{opts: opts, kubeconfig: kubeconfig}
    |> Runtime.install(fn opts -> opts end)
  end

  def run(_, %{env_config: env} = opts, context) do
    kubeconfig = get_default_kubeconfig()

    %InstallCommand{opts: opts, kubeconfig: kubeconfig}
    |> Runtime.install(fn opts -> opts end)
  end

  defp get_default_kubeconfig() do
    user_home = System.user_home!()
    kubecfg_default_dir = Path.join(user_home, ".kube")
    Path.join(kubecfg_default_dir, "config")
  end
end
