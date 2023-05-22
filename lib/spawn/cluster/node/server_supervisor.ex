defmodule Spawn.Cluster.Node.ServerSupervisor do
  @moduledoc false
  use Supervisor

  require Logger

  alias Spawn.Utils.Nats

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config,
      name: String.to_atom("#{String.capitalize(config.actor_system_name)}.NodeServer")
    )
  end

  def child_spec(config) do
    id = String.to_atom("#{String.capitalize(config.actor_system_name)}.NodeServer")

    %{
      id: id,
      start: {__MODULE__, :start_link, [config]}
    }
  end

  @impl true
  def init(config) do
    connection_name = Nats.connection_name()
    topic = Nats.get_topic(config.actor_system_name)

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
