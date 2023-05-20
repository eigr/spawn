defmodule Spawn.Utils.Nats do
  @moduledoc false

  alias Eigr.Functions.Protocol.InvocationRequest

  import Spawn.Utils.Common, only: [to_existing_atom_or_new: 1]

  @spec request(String.t(), InvocationRequest.t(), Keyword.t()) :: any() | {:ok, :async}
  def request(system, payload, opts \\ []) do
    async? = Keyword.get(opts, :async, false)
    conn = connection_name()
    topic = get_topic(system)

    # TODO: Verify if necessary default value
    trace_context = Keyword.get(opts, :trace_context)

    case async? do
      false ->
        Gnat.request(conn, topic, InvocationRequest.encode(payload), headers: trace_context)

      true ->
        :ok = Gnat.pub(conn, topic, InvocationRequest.encode(payload), headers: trace_context)

        {:ok, :async}
    end
  end

  @spec connection_name() :: atom()
  def connection_name(), do: to_existing_atom_or_new("spawn.internal.nats")

  def get_internal_nats_connection(config) do
    raw_hosts = config.internal_nats_hosts
    hosts_conn_map = get_nats_hosts(raw_hosts)

    # TODO: Get other parameters here to build complex connections

    hosts_conn_map
  end

  @spec get_nats_connection(map()) :: map()
  def get_nats_connection(config) do
    raw_hosts = config.pubsub_adapter_nats_hosts
    hosts_conn_map = get_nats_hosts(raw_hosts)

    # TODO: Get other parameters here to build complex connections

    hosts_conn_map
  end

  @spec get_topic(String.t()) :: String.t()
  def get_topic(system), do: "spawn.#{system}.actors.actions"

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
