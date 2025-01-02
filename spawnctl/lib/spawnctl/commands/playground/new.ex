defmodule SpawnCtl.Commands.Playground.New do
  @moduledoc """
  """
  use DoIt.Command,
    name: "new",
    description: "Create and run a new Spawn playground."

  alias SpawnCtl.K8s.K8sConn
  alias SpawnCtl.ReadmeFetcher
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
    recipe: "starwars",
    timeout: "5m"
  }

  @vsn "v2.0.0-RC1"

  option(:name, :string, "Defines the name of the Playground.",
    alias: :n,
    default: @default_opts.name
  )

  option(:namespace, :string, "Apply manifests on specified Kubernetes namespace.",
    alias: :n,
    default: "default"
  )

  option(
    :recipe,
    :string,
    "Playground recipe to install. See `spawnctl playground list` command.",
    alias: :r,
    default: @default_opts.recipe
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

  defp install_operator(
         %{k8s_flavour: "minikube", name: _name} = opts,
         kubecfg_default_file,
         _args,
         _context
       ) do
    install_opts = %{
      context: "minikube",
      env_config: "none",
      kubeconfig: kubecfg_default_file,
      version: @vsn
    }

    %RuntimeInstallCommand{opts: Map.merge(opts, install_opts), kubeconfig: kubecfg_default_file}
    |> Runtime.install(fn opts -> do_install_playground(opts) end)
  end

  defp install_operator(
         %{k8s_flavour: "k3d", name: name} = opts,
         kubecfg_default_file,
         _args,
         _context
       ) do
    install_opts = %{
      context: "k3d-#{name}",
      env_config: "none",
      kubeconfig: kubecfg_default_file,
      version: @vsn
    }

    %RuntimeInstallCommand{opts: Map.merge(opts, install_opts), kubeconfig: kubecfg_default_file}
    |> Runtime.install(fn opts -> do_install_playground(opts) end)
  end

  defp install_operator(
         %{k8s_flavour: _k8s_flavour, name: name} = opts,
         kubecfg_default_file,
         _args,
         _context
       ) do
    install_opts = %{
      context: name,
      env_config: "none",
      kubeconfig: kubecfg_default_file,
      version: @vsn
    }

    %RuntimeInstallCommand{opts: Map.merge(opts, install_opts), kubeconfig: kubecfg_default_file}
    |> Runtime.install(fn opts -> do_install_playground(opts) end)
  end

  defp do_install_playground(opts) do
    recipe_name = opts.recipe
    tmp_file = Path.join(System.tmp_dir!(), "#{recipe_name}-all-in-one.yaml")

    with {:k8s_conn, conn} <- {:k8s_conn, K8sConn.get(:prod, opts.kubeconfig, opts.context)},
         {:download, {:ok, path}} <-
           {:download, download_recipe_manifests(recipe_name, tmp_file)},
         {:manifests, {:ok, resources}} <-
           {:manifests, K8s.Resource.all_from_file(tmp_file, namespace: opts.namespace)} do
      log(:info, Emoji.hourglass(), "Installing playground...")

      case do_apply(conn, resources) do
        :ok ->
          ReadmeFetcher.fetch_readme(
            "eigr",
            "playground-recipes",
            "#{recipe_name}/README.md"
          )

        error ->
          log(
            :error,
            Emoji.tired_face(),
            "Error. Details: #{inspect(error)}"
          )
      end
    else
      {:error, %K8s.Conn.Error{message: message}} ->
        log(
          :error,
          Emoji.tired_face(),
          "Fail to connect to k8s cluster. Details #{inspect(message)}"
        )

      error ->
        log(
          :error,
          Emoji.exclamation(),
          "Failure occurring during install. Details #{inspect(error)}"
        )
    end
  end

  defp do_apply(conn, resources) do
    Enum.each(resources, fn %{"kind" => kind, "metadata" => %{"name" => name}} = resource ->
      operation = K8s.Client.create(resource)

      case K8s.Client.run(conn, operation) do
        {:ok, _deployment} ->
          log(
            :info,
            Emoji.floppy_disk(),
            "Resource #{name} of type #{kind} created successfully"
          )

        {:error, %K8s.Client.APIError{message: _message, reason: "AlreadyExists"}} ->
          log(
            :info,
            Emoji.ok(),
            "Resource #{name} of type #{kind} already installed. Nothing to do!"
          )

        {:error, %K8s.Client.APIError{message: message, reason: "NotFound"}} ->
          log(
            :error,
            Emoji.tired_face(),
            "Error. Not found dependant resource. Details: #{inspect(message)}"
          )

        error ->
          log(
            :error,
            Emoji.tired_face(),
            "Failure to install Resource #{name} of type #{kind}. Details #{inspect(error)}"
          )
      end
    end)
  end

  defp download_recipe_manifests(name, path) do
    manifest_url =
      "https://raw.githubusercontent.com/eigr/playground-recipes/main/#{name}/.k8s/all-in-one-install.yaml"

    with {:ok, response} <- Req.get(manifest_url),
         :ok <- File.write!(path, response.body) do
      {:ok, path}
    end
  end
end
