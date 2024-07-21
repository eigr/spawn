defmodule Spawnctl.Commands.Playground.K8s.Minikube do
  @moduledoc """
  A module to manage Minikube clusters from Elixir.
  """
  alias SpawnCtl.Util.Emoji
  import SpawnCtl.Util, only: [log: 3, os_exec: 2]

  @minikube_cmd System.find_executable("minikube")

  defmodule Install do
    alias Spawnctl.Commands.Playground.K8s.Minikube
    alias Spawnctl.Commands.Playground.K8s.Minikube.Install, as: InstallCommand

    defstruct opts: %{}

    defimpl Spawnctl.Commands.Playground.K8s.Behavior.Installer, for: __MODULE__ do
      @impl true
      def install(
            %InstallCommand{
              opts: opts
            } = _strategy,
            callback
          )
          when is_function(callback) do
        case Minikube.start_cluster(Map.get(opts, :name, "spawn-playground")) do
          {:ok, _output} ->
            callback.(opts)

          {:error, exit_code, _output} ->
            System.stop(exit_code)
        end
      end
    end
  end

  @doc """
  Checks if Minikube is already started.
  """
  def minikube_started? do
    case os_exec(@minikube_cmd, ["status"]) do
      {output, 0} ->
        String.contains?(output, "host: Running") and
          String.contains?(output, "kubelet: Running") and
          String.contains?(output, "apiserver: Running")

      {_, _} ->
        false
    end
  rescue
    _ ->
      false
  end

  @doc """
  Starts a Minikube cluster with the specified driver.
  """
  def start_cluster(_cluster_name) do
    if minikube_installed?() do
      if minikube_started?() do
        log(
          :info,
          Emoji.ok(),
          "Minikube cluster is already started."
        )

        {:ok, nil}
      else
        case os_exec(@minikube_cmd, ["start", "--driver", "docker"]) do
          {output, 0} ->
            log(
              :info,
              Emoji.ok(),
              "Minikube cluster started successfully."
            )

            {:ok, output}

          {output, exit_code} ->
            log(
              :error,
              Emoji.tired_face(),
              "Failed to start Minikube cluster. Exit code: #{exit_code}"
            )

            {:error, exit_code, output}
        end
      end
    else
      log(
        :error,
        Emoji.tired_face(),
        "Minikube is not installed on the host system."
      )

      {:error, 1, "Minikube is not installed on the host system."}
    end
  end

  @doc """
  Stops the Minikube cluster.
  """
  def stop_cluster do
    if minikube_installed?() do
      case os_exec(@minikube_cmd, ["stop"]) do
        {output, 0} ->
          log(
            :info,
            Emoji.ok(),
            "Minikube cluster stopped successfully."
          )

          {:ok, output}

        {output, exit_code} ->
          log(
            :error,
            Emoji.tired_face(),
            "Failed to stop Minikube cluster. Exit code: #{exit_code}"
          )

          {:error, 1, "Failed to stop Minikube cluster. Exit code: #{exit_code}"}
      end
    else
      log(
        :error,
        Emoji.tired_face(),
        "Minikube is not installed on the host system."
      )

      {:error, 1, "Minikube is not installed on the host system."}
    end
  end

  @doc """
  Deletes the Minikube cluster.
  """
  def delete_cluster do
    if minikube_installed?() do
      case os_exec(@minikube_cmd, ["delete"]) do
        {output, 0} ->
          log(
            :info,
            Emoji.ok(),
            "Minikube cluster deleted successfully."
          )

          {:ok, output}

        {output, exit_code} ->
          log(
            :error,
            Emoji.tired_face(),
            "Failed to delete Minikube cluster. Exit code: #{exit_code}"
          )

          {:error, 1, "Failed to delete Minikube cluster. Exit code: #{exit_code}"}
      end
    else
      log(
        :error,
        Emoji.tired_face(),
        "Minikube is not installed on the host system."
      )

      {:error, 1, "Minikube is not installed on the host system."}
    end
  end

  @doc """
  Checks if Minikube is installed on the host system.
  """
  def minikube_installed? do
    case os_exec(@minikube_cmd, ["version"]) do
      {_, 0} ->
        true

      {_, _} ->
        false
    end
  rescue
    _ ->
      false
  end
end
