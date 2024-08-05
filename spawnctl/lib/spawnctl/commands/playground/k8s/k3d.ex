defmodule Spawnctl.Commands.Playground.K8s.K3d do
  @moduledoc """
  A module to manage K3d (K3s in Docker) clusters from Elixir.

  This module provides functionality to:
    - Check if K3d is installed on the host system.
    - Check if a K3d cluster is already created.
    - Create a K3d cluster with 3 nodes (1 server and 2 agents).
    - Delete a K3d cluster.
  """
  alias SpawnCtl.Util.Emoji
  import SpawnCtl.Util, only: [log: 3, os_exec: 2]

  defmodule Install do
    @moduledoc """
    The Install module within K3d to handle installation and cluster management tasks.

    It implements the `Spawnctl.Commands.Playground.K8s.Behavior.Installer` protocol for managing K3d clusters.
    """
    alias Spawnctl.Commands.Playground.K8s.K3d
    alias Spawnctl.Commands.Playground.K8s.K3d.Install, as: InstallCommand

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
        case K3d.create_cluster(Map.get(opts, :name, "spawn-playground")) do
          {:ok, _output} ->
            callback.(opts)

          {:error, exit_code, _output} ->
            System.stop(exit_code)
        end
      end
    end
  end

  @doc """
  Checks if a K3d cluster is already created.
  """
  def k3d_cluster_created?(cluster_name \\ "k3s-default") do
    k3d_cmd = System.find_executable("k3d")

    case os_exec(k3d_cmd, ["cluster", "list"]) do
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
  Creates a K3d cluster with 3 nodes and the specified name.
  """
  def create_cluster(cluster_name, opts \\ %{timeout: "5m"}) do
    k3d_cmd = System.find_executable("k3d")

    if k3d_installed?() do
      if k3d_cluster_created?(cluster_name) do
        log(
          :info,
          Emoji.ok(),
          "K3d cluster '#{cluster_name}' is already created."
        )

        {:ok, nil}
      else
        case os_exec(k3d_cmd, [
               "cluster",
               "create",
               cluster_name,
               "--agents",
               "3",
               "--timeout",
               opts.timeout
             ]) do
          {output, 0} ->
            log(
              :info,
              Emoji.ok(),
              "K3d cluster '#{cluster_name}' created successfully with 3 nodes."
            )

            {:ok, output}

          {output, exit_code} ->
            log(
              :error,
              Emoji.tired_face(),
              "Failed to create K3d cluster. Exit code: #{exit_code}"
            )

            {:error, exit_code, output}
        end
      end
    else
      log(
        :error,
        Emoji.tired_face(),
        "K3d is not installed on the host system."
      )

      {:error, 1, "K3d is not installed on the host system."}
    end
  end

  @doc """
  Deletes the K3d cluster with the specified name.
  """
  def delete_cluster(cluster_name \\ "k3s-default") do
    k3d_cmd = System.find_executable("k3d")

    if k3d_installed?() do
      case os_exec(k3d_cmd, ["cluster", "delete", cluster_name]) do
        {output, 0} ->
          log(
            :info,
            Emoji.ok(),
            "K3d cluster '#{cluster_name}' deleted successfully."
          )

          {:ok, output}

        {output, exit_code} ->
          log(
            :error,
            Emoji.tired_face(),
            "Failed to delete K3d cluster. Exit code: #{exit_code}"
          )

          {:error, exit_code, output}
      end
    else
      log(
        :error,
        Emoji.tired_face(),
        "K3d is not installed on the host system."
      )

      {:error, 1, "K3d is not installed on the host system."}
    end
  end

  @doc """
  Checks if K3d is installed on the host system.
  """
  def k3d_installed? do
    k3d_cmd = System.find_executable("k3d")

    case os_exec(k3d_cmd, ["version"]) do
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
