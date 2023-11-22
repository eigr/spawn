defmodule Spawn.Cluster.Node.ServerSupervisor do
  @moduledoc false
  use Supervisor

  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config
  alias Spawn.Utils.Nats

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts,
      name: String.to_atom("#{String.capitalize(Config.get(:actor_system_name))}.NodeServer")
    )
  end

  def child_spec(opts) do
    id = String.to_atom("#{String.capitalize(Config.get(:actor_system_name))}.NodeServer")

    %{
      id: id,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def init(_opts) do
    connection_name = Nats.connection_name()
    topic = Nats.get_topic(Config.get(:actor_system_name))

    Logger.debug(
      "Mapping Node #{inspect(Node.self())} to Nats Topic #{topic} on Connection #{inspect(connection_name)}"
    )

    connection_params = %{
      connection_name: connection_name,
      module: Spawn.Cluster.Node.Server,
      subscription_topics: [
        %{topic: topic, queue_group: topic}
      ]
    }

    children = [
      {Gnat.ConsumerSupervisor, connection_params}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
