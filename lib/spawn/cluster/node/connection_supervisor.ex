defmodule Spawn.Cluster.Node.ConnectionSupervisor do
  @moduledoc false
  use Supervisor

  require Logger

  alias Spawn.Utils.Nats

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
  def init(config) do
    connection_name = Nats.connection_name()

    Logger.debug("Creating Nats Connection #{inspect(connection_name)}")

    children = [
      {Gnat.ConnectionSupervisor, connection_settings(connection_name, config)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp connection_settings(name, config) do
    %{
      name: name,
      backoff_period: config.internal_nats_connection_backoff_period,
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
