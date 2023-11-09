defmodule Sidecar.ProcessSupervisor do
  @moduledoc false
  use Supervisor

  @shutdown_timeout_ms 330_000

  @impl true
  def init(config) do
    children =
      [
        {Sidecar.MetricsSupervisor, config},
        statestores(),
        Spawn.Supervisor.child_spec(config),
        Actors.Supervisors.ProtocolSupervisor.child_spec(config),
        Actors.Supervisors.ActorSupervisor.child_spec(config)
      ]
      |> Enum.reject(&is_nil/1)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(config) do
    Supervisor.start_link(
      __MODULE__,
      config,
      name: __MODULE__,
      # wait until for 5 and a half minutes
      shutdown: @shutdown_timeout_ms,
      strategy: :one_for_one
    )
  end

  if Code.ensure_loaded?(Statestores.Supervisor) do
    defp statestores, do: Statestores.Supervisor.child_spec()
  else
    defp statestores, do: nil
  end
end
