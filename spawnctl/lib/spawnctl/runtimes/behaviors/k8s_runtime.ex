defmodule Spawnctl.Runtimes.Behaviors.K8sRuntime do
  @moduledoc """

  """

  defmodule Install do
    @moduledoc """

    """
    alias SpawnCtl.K8s.K8sConn
    alias SpawnCtl.Util.Emoji
    alias Spawnctl.Runtimes.Behaviors.K8sRuntime.Install, as: InstallCommand

    import SpawnCtl.Util, only: [log: 3]

    defstruct opts: %{}, kubeconfig: nil

    defimpl SpawnCtl.Commands.Install.Behavior.Runtime, for: __MODULE__ do
      @vsn "v1.4.3"
      @manifest_filename "spawn-manifest.yaml"
      @default_namespace "eigr-functions"

      @impl true
      def install(
            %InstallCommand{
              kubeconfig: kubeconfig,
              opts: source_opts
            } = _strategy,
            callback
          )
          when is_function(callback, 1) do
        tmp_file = Path.join(System.tmp_dir!(), @manifest_filename)
        opts = [namespace: @default_namespace]

        log(
          :info,
          Emoji.hourglass(),
          "Installing Spawn using follow kube context file: #{kubeconfig}"
        )

        version = Map.get(source_opts, :version, @vsn)

        manifest_url =
          "https://github.com/eigr/spawn/releases/download/#{version}/manifest.yaml"

        with conn <- K8sConn.get(:prod, kubeconfig, source_opts.context),
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
            end
          )

          log(:info, Emoji.rocket(), "Done!")
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

        callback.(source_opts)
      end
    end
  end
end
