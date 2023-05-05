defmodule Spawn.Utils.Nats do
  @moduledoc false

  alias alias Eigr.Functions.Protocol.InvocationRequest

  import Spawn.Utils.Common, only: [to_existing_atom_or_new: 1]

  def connection_name(), do: to_existing_atom_or_new("spawn.internal.nats")

  def get_internal_nats_connection(config) do
    raw_hosts = config.internal_nats_hosts
    hosts_conn_map = get_nats_hosts(raw_hosts)

    # TODO: Get other parameters here to build complex connections

    hosts_conn_map
  end

  def get_nats_connection(config) do
    raw_hosts = config.pubsub_adapter_nats_hosts
    hosts_conn_map = get_nats_hosts(raw_hosts)

    # TODO: Get other parameters here to build complex connections

    hosts_conn_map
  end

  def request(system, payload, _opts \\ []) do
    topic = "spawn.#{system}.actors.actions"
    Gnat.request(connection_name(), topic, InvocationRequest.encode(payload))
  end

  defp get_nats_hosts(raw_hosts) do
    String.split(raw_hosts, ",")
    |> Enum.map(fn host ->
      host_port = String.replace(host, "nats://", "")
      host = String.split(host_port, ":") |> List.first()
      port = String.split(host_port, ":") |> List.last() |> String.to_integer()
      %{host: host, port: port, no_responders: true}
    end)
    |> List.first()
  end
end
