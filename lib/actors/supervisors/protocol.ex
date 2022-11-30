defmodule Actors.Supervisors.ProtocolSupervisor do
  use Supervisor
  require Logger

  alias Actors.Config.Vapor, as: Config

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
    _actors_config = Config.load(Actors)
    Protobuf.load_extensions()

    children = [
      {Registry, keys: :unique, name: Actors.NodeRegistry},
      {Finch,
       name: SpawnHTTPClient,
       pools: %{
         :default => [size: 32, count: 8]
       }}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
