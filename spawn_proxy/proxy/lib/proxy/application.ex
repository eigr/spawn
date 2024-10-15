defmodule Proxy.Application do
  @moduledoc false
  use Application
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config

  @impl true
  def start(type, args), do: do_start(type, args)

  defp do_start(_type, _args) do
    {u_secs, reply} =
      :timer.tc(fn ->
        if function_exported?(:proc_lib, :set_label, 1) do
          apply(:proc_lib, :set_label, ["Spawn.Proxy.Application"])
        end

        OpentelemetryEcto.setup([:spawn_statestores, :repo])
        Config.load()

        Logger.configure(level: Config.get(:logger_level))

        children = [
          {Proxy.Supervisor, []}
        ]

        opts = [strategy: :one_for_one, name: Proxy.RootSupervisor]

        Supervisor.start_link(children, opts)
      end)

    case reply do
      {:ok, pid} ->
        Logger.info(
          "Proxy Application started successfully in #{u_secs / 1_000_000}ms. Running with #{inspect(System.schedulers_online())} schedulers."
        )

        {:ok, pid}

      failure ->
        raise RuntimeError, "Failed to start Proxy Application: #{inspect(failure)}"
    end
  end

  @impl true
  def prep_stop(_args) do
    Logger.info("Proxy Application stopping...")
  end

  @impl true
  def stop(_args) do
    Logger.info("Proxy Application stopped")
  end
end
