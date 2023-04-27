defmodule Sidecar.ProcessSupervisor do
  @moduledoc false
  use Supervisor

  @impl true
  def init(config) do
    children =
      [
        statestores(),
        {Sidecar.MetricsSupervisor, config},
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
      shutdown: 120_000,
      strategy: :one_for_one
    )
  end

  if Code.ensure_loaded?(Statestores.Supervisor) do
    defp statestores, do: Statestores.Supervisor.child_spec()
  else
    defp statestores, do: nil
  end
end
