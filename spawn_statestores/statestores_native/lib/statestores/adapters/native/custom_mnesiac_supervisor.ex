defmodule Statestores.Adapters.Native.CustomMnesiacSupervisor do
  @moduledoc false
  require Logger

  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [],
      name: Statestores.Adapters.Native.CustomMnesiacSupervisor
    )
  end

  @impl true
  def init(_) do
    _ = Logger.info("[mnesiac:#{node()}] mnesiac starting, with #{inspect(Node.list())}")

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
