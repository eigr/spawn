defmodule SpawnCli.Commands.Install do
  use DoIt.Command,
    name: "install",
    description: "Install Spawn Operator in Kubernetes cluster."

  @vsn "v1.4.1"
  @workspace System.tmp_dir!()
  @manifest_filename "spawn-manifest.yaml"

  alias SpawnCli.K8s.K8sConn

  option(:kubeconfig, :string, "Load a Kubernetes kube config file.",
    alias: :k,
    default: "~/.kube/config"
  )

  option(:envconfig, :string, "Load a Kubernetes kube config from environment variable.",
    alias: :e,
    default: "none"
  )

  option(:context, :string, "Apply manifest on specified Kubernetes Context.",
    alias: :c,
    default: "default"
  )

  option(:version, :string, "Install Operator with a specific version.",
    alias: :V,
    default: @vsn,
    allowed_values: [
      @vsn
    ]
  )

  def run(_, %{context: ctx, kubeconfig: cfg, version: version, envconfig: env} = _opts, context) do
    tmp_file = Path.join(@workspace, @manifest_filename)
    opts = [namespace: "eigr-functions"]
    IO.inspect(cfg, label: "Installing Spawn using file ")

    kubeconfig =
      if env == "none" && File.exists?(cfg) do
        cfg
      else
        kcfg = System.get_env(env)

        if not is_nil(kcfg) && File.exists?(kcfg) do
          kcfg
        else
          IO.puts(
            :stderr,
            "You need to specify a valid kubeconfig file or kubeconfig environment variable. See options: [--kubeconfig, --envconfig] "
          )

          help(context)
          System.stop(1)
        end
      end

    manifest_url =
      "https://github.com/eigr/spawn/releases/download/#{version}/manifest.yaml"

    with conn <- K8sConn.get(:prod, cfg, ctx),
         {:ok, response} <- Req.get(manifest_url),
         :ok <- File.write!(tmp_file, response.body),
         {:ok, resources} <- K8s.Resource.all_from_file(tmp_file, opts) do
      # Create ns eigr-functions if not exists
      ns = %{
        "apiVersion" => "v1",
        "kind" => "Namespace",
        "metadata" => %{"name" => "eigr-functions"}
      }

      resources = [ns] ++ resources

      Enum.each(
        resources,
        fn %{"kind" => kind, "metadata" => %{"name" => name}} = resource ->
          operation = K8s.Client.create(resource)

          case K8s.Client.run(conn, operation) do
            {:ok, _deployment} ->
              IO.puts("Resource #{name} of type #{kind} created successfully")

            {:error, %K8s.Client.APIError{message: _message, reason: "AlreadyExists"}} ->
              IO.puts("Resource #{name} of type #{kind} already installed. Nothing to do!")

            {:error, %K8s.Client.APIError{message: message, reason: "NotFound"}} ->
              IO.puts(
                :stderr,
                "Error. Not found dependant resource. Details: #{inspect(message)}"
              )

            error ->
              IO.puts(
                :stderr,
                "Failure to install Resource #{name} of type #{kind}. Details #{inspect(error)}"
              )
          end
        end
      )

      IO.puts("Done!")
    else
      error -> IO.puts(:stderr, "Failure occurring during install. Details #{inspect(error)}")
    end
  end
end
