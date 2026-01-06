defmodule Actors.Supervisors.ActorProjectionHandlerSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  alias Actors.Config.PersistentTermConfig, as: Config
  alias Actors.Actor.Entity.Lifecycle.StreamConsumer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def init(_opts) do
    projections = :persistent_term.get("projections", [])
    Logger.info("Starting projection handlers for: #{inspect(projections)}")

    projection_children =
      projections
      |> Enum.uniq()
      |> Enum.map(fn projection_name ->
        config = :persistent_term.get("actor-#{projection_name}", %{})
        system = Config.get(:actor_system_name)
        actor_name = String.replace("#{system}-#{projection_name}", ".", "-")

        %{
          id: actor_name,
          start:
            {StreamConsumer, :start_link,
             [
               %{
                 actor_name: actor_name,
                 projection_pid: self(),
                 strict_ordering: config.strict_events_ordering
               }
             ]}
        }
      end)

    children =
      [
        supervisor_process_logger(__MODULE__)
      ] ++ projection_children

    Supervisor.init(children, strategy: :one_for_one)
  end
end
