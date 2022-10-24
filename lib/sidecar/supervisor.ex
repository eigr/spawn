defmodule Sidecar.Supervisor do
  @moduledoc false
  use Supervisor

  @impl true
  def init(config) do
    children =
      [
        Spawn.Supervisor.child_spec(config),
        statestores(),
        Actors.Supervisors.ProtocolSupervisor.child_spec(config),
        Actors.Supervisors.EntitySupervisor.child_spec(config),
        %{
          id: StateHandoffJoinTask,
          restart: :transient,
          start: {
            Task,
            :start_link,
            [
              fn ->
                Node.list()
                |> Enum.each(fn node ->
                  Spawn.Cluster.StateHandoff.join(node)
                end)
              end
            ]
          }
        }
      ]
      |> Enum.reject(&is_nil/1)

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

  if Code.ensure_loaded?(Statestores.Supervisor) do
    defp statestores, do: Statestores.Supervisor.child_spec()
  else
    defp statestores, do: nil
  end
end
