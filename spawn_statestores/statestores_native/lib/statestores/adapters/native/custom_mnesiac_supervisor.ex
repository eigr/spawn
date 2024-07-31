defmodule Statestores.Adapters.Native.CustomMnesiacSupervisor do
  @moduledoc false
  require Logger

  use Supervisor

  alias Actors.Config.PersistentTermConfig, as: Config

  import Statestores.Util, only: [create_directory: 1]

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [],
      name: Statestores.Adapters.Native.CustomMnesiacSupervisor
    )
  end

  @impl true
  def init(_) do
    _ = Logger.info("[mnesiac:#{node()}] mnesiac starting, with #{inspect(Node.list())}")

    # If we ever change to Statefulset instead of deployment
    # we need to set the mnesia path to be dynamic based on pod name.
    # For the time being we only support one storage per system.
    if system = Config.get(:actor_system_name) do
      # this is necessary to be called on runtime, this will set the
      # mnesia path to be dynamic based on configured volume mount
      statestore_data_path =
        if System.get_env("MIX_ENV") != "prod" do
          "#{System.tmp_dir!()}/data/#{system}"
        else
          "/data/#{system}"
        end

      create_directory(statestore_data_path)
      Application.put_env(:mnesia, :dir, statestore_data_path |> to_charlist())
    end

    Mnesiac.init_mnesia(Node.list())
    |> case do
      :ok ->
        :ok

      {:error, {:failed_to_connect_node, node}} ->
        Logger.warning("Failed to connect node: #{node}")
    end

    _ = Logger.info("[mnesiac:#{node()}] mnesiac started")

    Supervisor.init([],
      strategy: :one_for_one,
      name: Statestores.Adapters.Native.CustomMnesiacSupervisor
    )
  end
end
