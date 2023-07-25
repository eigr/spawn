defmodule Proxy.Application do
  @moduledoc false
  use Application
  require Logger

  alias Actors.Config.Vapor, as: Config

  @impl true
  def start(type, args), do: do_start(type, arg)

  defp do_start(_type, _arg) do
    [time: _time, humanized_duration: humanized_duration, reply: reply] =
      Timer.tc(fn ->
        config = Config.load(__MODULE__)

        children = [
          {Proxy.Supervisor, config}
        ]

        opts = [strategy: :one_for_one, name: Proxy.RootSupervisor]

        Supervisor.start_link(children, opts)
      end)

    case reply do
      {:ok, pid} ->
        Logger.info(
          "Proxy Application started successfully in #{humanized_duration}. Running with #{inspect(System.schedulers_online())} schedulers."
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
