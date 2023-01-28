defmodule Actors.Supervisors.ActorSupervisor do
  @moduledoc false
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
  def init(config) do
    Protobuf.load_extensions()

    children = [
      get_pubsub_adapter(config),
      Actors.Actor.Entity.Supervisor.child_spec(),
      %{
        id: :actor_registry_task,
        start:
          {Task, :start_link,
           [
             fn ->
               Process.flag(:trap_exit, true)

               receive do
                 {:EXIT, _pid, _reason} ->
                   Actors.Registry.ActorRegistry.node_cleanup(Node.self())
               end
             end
           ]}
      },
      {Highlander, Actors.Actor.InvocationScheduler.child_spec()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_pubsub_adapter(config) do
    case config.pubsub_adapter do
      "nats" ->
        {
          Phoenix.PubSub,
          name: :actor_channel,
          adapter: PhoenixPubsubNats,
          connection: get_nats_connection(config)
        }

      _ ->
        {Phoenix.PubSub, name: :actor_channel}
    end
  end

  defp get_nats_connection(config) do
    raw_hosts = config.pubsub_adapter_nats_hosts
    hosts_conn_map = get_nats_hosts(raw_hosts)

    # TODO: Get other parameters here to build complex connections

    hosts_conn_map
  end

  defp get_nats_hosts(raw_hosts) do
    String.split(raw_hosts, ",")
    |> Enum.map(fn host ->
      host_port = String.replace(host, "nats://", "")
      host = String.split(host_port, ":") |> List.first()
      port = String.split(host_port, ":") |> List.last() |> String.to_integer()
      %{host: host, port: port}
    end)
    |> List.first()
  end
end
