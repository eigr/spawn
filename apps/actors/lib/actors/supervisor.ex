defmodule Actors.Supervisor do
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
      {Registry, keys: :unique, name: Actors.NodeRegistry},
      {Finch,
       name: SpawnHTTPClient,
       pools: %{
         :default => [size: 32, count: 8]
       }},
      Actors.Registry.ActorRegistry.Supervisor,
      Actors.Actor.Registry.child_spec(),
      Actors.Actor.Entity.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
