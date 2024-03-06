defmodule Sidecar.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  @shutdown_timeout_ms 342_000

  @impl true
  def init(opts) do
    if function_exported?(:proc_lib, :set_label, 1) do
      apply(:proc_lib, :set_label, ["Spawn.Sidecar"])
    end

    children =
      [
        supervisor_process_logger(__MODULE__),
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
