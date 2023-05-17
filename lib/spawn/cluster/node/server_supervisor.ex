defmodule Spawn.Cluster.Node.ServerSupervisor do
  @moduledoc false
  use Supervisor

  require Logger

  alias Spawn.Utils.Nats

  @backoff_period 3_000

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
      {Gnat.ConnectionSupervisor, connection_settings(connection_name, config)},
      {Gnat.ConsumerSupervisor, connection_params}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp connection_settings(name, config) do
    %{
      name: name,
      backoff_period: @backoff_period,
      connection_settings: [
        Map.merge(
          Spawn.Utils.Nats.get_internal_nats_connection(config),
          determine_auth_method(name, config)
        )
      ]
    }
  end

  defp determine_auth_method(_name, _config) do
    %{}
  end
end
