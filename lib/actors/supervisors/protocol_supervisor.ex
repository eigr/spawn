defmodule Actors.Supervisors.ProtocolSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Actors.Config.Vapor, as: Config

  @default_finch_pool_count System.schedulers_online()
  @default_finch_pool_max_idle_timeout 1_000
  @default_finch_pool_size 10

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
         :default => [
           size: @default_finch_pool_size,
           count: @default_finch_pool_count,
           pool_max_idle_time: @default_finch_pool_max_idle_timeout
         ]
       }}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
