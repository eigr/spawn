defmodule Sidecar.Supervisor do
  @moduledoc false
  use Supervisor

  @impl true
  def init(config) do
    children = [
      Spawn.Supervisor.child_spec(config),
      Statestores.Supervisor.child_spec(),
      Actors.Supervisors.ProtocolSupervisor.child_spec(config),
      Actors.Supervisors.EntitySupervisor.child_spec(config)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(config) do
    Supervisor.start_link(
      __MODULE__,
      config,
      shutdown: 120_000,
      strategy: :one_for_one
    )
  end
end
