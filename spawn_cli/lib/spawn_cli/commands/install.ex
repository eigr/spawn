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
    default: "KUBECONFIG"
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

  def run(_, %{context: ctx, kubeconfig: cfg, version: version, envconfig: env} = _opts, _context) do
    IO.inspect(cfg, label: "Installing Spawn using file: ")
    tmp_file = Path.join(@workspace, @manifest_filename)

    release_version =
      if version == @vsn do
        @vsn
      else
        version
      end

    opts = [namespace: "spawn-system"]

    manifest_url =
      "https://github.com/eigr/spawn/releases/download/#{release_version}/manifest.yaml"

    with conn <- K8sConn.get(:prod, cfg, ctx),
         {:ok, response} <- Req.get(manifest_url),
         :ok <- File.write!(tmp_file, response.body),
         {:ok, resource} <- K8s.Resource.from_file(tmp_file, opts),
         operation <- K8s.Client.create(resource),
         {:ok, deployment} <- K8s.Client.run(conn, operation) do
      IO.inspect(deployment, label: "Deployment")
      IO.puts("Spawn Operator installed with success!")
    else
      error -> IO.inspect(error, label: "Failure occurring during install")
    end
  end
end
