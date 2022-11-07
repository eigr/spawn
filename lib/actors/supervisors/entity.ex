defmodule Actors.Supervisors.EntitySupervisor do
  use Supervisor
  require Logger

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def child_spec(config) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [config]}
    }
  end

  @impl true
  def init(_config) do
    Protobuf.load_extensions()

    children = [
      {Phoenix.PubSub, name: :actor_channel},
      Actors.Actor.Entity.Supervisor.child_spec(),
      Actors.Registry.ActorRegistry.child_spec(),
      {Highlander, Actors.Actor.Scheduler.child_spec()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
