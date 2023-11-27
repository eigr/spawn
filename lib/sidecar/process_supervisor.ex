defmodule Sidecar.ProcessSupervisor do
  @moduledoc false
  use Supervisor

  @impl true
  def init(opts) do
    children =
      [
        {Sidecar.MetricsSupervisor, opts},
        statestores(),
        Spawn.Supervisor.child_spec(opts),
        Actors.Supervisors.ProtocolSupervisor.child_spec(opts),
        Actors.Supervisors.ActorSupervisor.child_spec(opts)
      ]
      |> Enum.reject(&is_nil/1)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(opts) do
    Supervisor.start_link(
      __MODULE__,
      opts,
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  if Code.ensure_loaded?(Statestores.Supervisor) do
    defp statestores, do: Statestores.Supervisor.child_spec()
  else
    defp statestores, do: nil
  end
end
