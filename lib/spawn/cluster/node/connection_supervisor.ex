defmodule Spawn.Cluster.Node.ConnectionSupervisor do
  @moduledoc false
  use Supervisor

  require Logger

  alias Spawn.Utils.Nats
  alias Actors.Config.PersistentTermConfig, as: Config

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
  def init(opts) do
    connection_name = Nats.connection_name()

    Logger.debug("Creating Nats Connection #{inspect(connection_name)}")

    children = [
      {Gnat.ConnectionSupervisor, connection_settings(connection_name, opts)}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp connection_settings(name, opts) do
    %{
      name: name,
      backoff_period: Config.get(:internal_nats_connection_backoff_period),
      connection_settings: [
        Map.merge(
          Spawn.Utils.Nats.get_internal_nats_connection(opts),
          determine_auth_method(name, opts)
        )
      ]
    }
  end

  defp determine_auth_method(_name, _opts) do
    %{}
  end
end
