defmodule Spawnctl.Commands.Playground.K8s.Kind do
  @moduledoc """
  A module to manage Kind (Kubernetes in Docker) clusters from Elixir.
  """
  alias SpawnCtl.Util.Emoji
  import SpawnCtl.Util, only: [log: 3, os_exec: 2]

  defmodule Install do
    alias Spawnctl.Commands.Playground.K8s.Kind
    alias Spawnctl.Commands.Playground.K8s.Kind.Install, as: InstallCommand

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
        case Kind.create_cluster(Map.get(opts, :name, "spawn-playground")) do
          {:ok, _output} ->
            callback.(opts)

          {:error, exit_code, _output} ->
            System.stop(exit_code)
        end
      end
    end
  end

  @doc """
  Checks if a Kind cluster is already created.
  """
  def kind_cluster_created?(cluster_name \\ "kind") do
    kind_cmd = System.find_executable("kind")

    case os_exec(kind_cmd, ["get", "clusters"]) do
      {output, 0} ->
        String.contains?(output, cluster_name)

      {_, _} ->
        false
    end
  rescue
    _ ->
      false
  end

  @doc """
  Creates a Kind cluster with the specified name.
  """
  def create_cluster(cluster_name) do
    kind_cmd = System.find_executable("kind")

    if kind_installed?() do
      if kind_cluster_created?(cluster_name) do
        log(
          :info,
          Emoji.ok(),
          "Kind cluster '#{cluster_name}' is already created."
        )

        {:ok, nil}
      else
        case os_exec(kind_cmd, ["create", "cluster", "--name", cluster_name]) do
          {output, 0} ->
            log(
              :info,
              Emoji.ok(),
              "Kind cluster '#{cluster_name}' created successfully."
            )

            {:ok, output}

          {output, exit_code} ->
            log(
              :error,
              Emoji.tired_face(),
              "Failed to create Kind cluster. Exit code: #{exit_code}"
            )

            {:error, exit_code, output}
        end
      end
    else
      log(
        :error,
        Emoji.tired_face(),
        "Kind is not installed on the host system."
      )

      {:error, 1, "Kind is not installed on the host system."}
    end
  end

  @doc """
  Deletes the Kind cluster with the specified name.
  """
  def delete_cluster(cluster_name \\ "kind") do
    kind_cmd = System.find_executable("kind")

    if kind_installed?() do
      case os_exec(kind_cmd, ["delete", "cluster", "--name", cluster_name]) do
        {output, 0} ->
          log(
            :info,
            Emoji.ok(),
            "Kind cluster '#{cluster_name}' deleted successfully."
          )

          {:ok, output}

        {output, exit_code} ->
          log(
            :error,
            Emoji.tired_face(),
            "Failed to delete Kind cluster. Exit code: #{exit_code}"
          )

          {:error, exit_code, output}
      end
    else
      log(
        :error,
        Emoji.tired_face(),
        "Kind is not installed on the host system."
      )

      {:error, 1, "Kind is not installed on the host system."}
    end
  end

  @doc """
  Checks if Kind is installed on the host system.
  """
  def kind_installed? do
    kind_cmd = System.find_executable("kind")

    case os_exec(kind_cmd, ["version"]) do
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
