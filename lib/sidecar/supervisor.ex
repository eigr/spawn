defmodule Sidecar.Supervisor do
  @moduledoc false
  use Supervisor

  @shutdown_timeout_ms 342_000

  @impl true
  def init(opts) do
    children =
      [
        {Sidecar.GracefulShutdown, opts},
        {Sidecar.ProcessSupervisor, opts}
      ]
      |> Enum.reject(&is_nil/1)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(opts) do
    Supervisor.start_link(
      __MODULE__,
      opts,
      name: __MODULE__,
      # wait for 5,7 minutes to stop
      shutdown: @shutdown_timeout_ms,
      strategy: :one_for_one
    )
  end
end
