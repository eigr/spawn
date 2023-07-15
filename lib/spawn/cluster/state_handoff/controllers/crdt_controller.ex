defmodule Spawn.Cluster.StateHandoff.Controllers.CrdtController do
  @moduledoc """
  This handles state handoff in a cluster.

  It uses the DeltaCrdt library to handle a distributed state, which is an eventually consistent replicated data type.
  The module starts a GenServer that monitors nodes in the cluster, and when a new node comes up it sends a "set_neighbours"
  message to that node's GenServer process with its own DeltaCrdt process ID. This is done to ensure that changes in either node's
  state are reflected across both.

  The module also handles other messages like "handoff" and "get" to put and retrieve data from the DeltaCrdt state, respectively.
  """
  require Logger

  @behaviour Spawn.Cluster.StateHandoff.ControllerBehaviour

  import Spawn.Utils.Common, only: [generate_key: 1]

  @type node_type :: term()

  @type config :: map()

  @type data :: any()

  @type new_data :: data()

  @type id :: Eigr.Functions.Protocol.Actors.ActorId.t()

  @type host :: Actors.Registry.HostActor.t()

  @type hosts :: list(Actors.Registry.HostActor.t())

  @type timer :: {atom(), integer()}

  @call_timeout 15_000

  @default_sync_interval 2
  @default_ship_interval 2
  @default_ship_debounce 2
  @default_neighbours_sync_interval 60_000

  def get_crdt_pid do
    :persistent_term.get(__MODULE__, {:error, Node.self()})
  end

  @doc """
  Cluster HostActor cleanup
  """
  @impl true
  def clean(node, data) do
    Logger.debug("Received cleanup action from Node #{inspect(node)}")

    crdt_pid = get_crdt_pid()
    actors = DeltaCrdt.to_map(crdt_pid)

    new_hosts =
      actors
      |> Enum.map(fn {key, hosts} ->
        hosts_not_in_node = Enum.reject(hosts, &(&1.node == node))

        {key, hosts_not_in_node}
      end)
      |> Map.new()

    drop_operations = actors |> Map.keys() |> Enum.map(&{:remove, [&1]})
    merge_operations = Enum.map(new_hosts, fn {key, value} -> {:add, [key, value]} end)

    # this is calling the internals of DeltaCrdt GenServer function (to keep atomicity in check)
    GenServer.call(crdt_pid, {:bulk_operation, drop_operations ++ merge_operations})

    Logger.debug("Hosts cleaned for node #{inspect(node)}")
    data
  end

  @impl true
  @spec get_by_id(id(), data()) :: {new_data(), hosts()}
  def get_by_id(id, %{crdt_pid: _crdt_pid} = data) do
    key = generate_key(id)

    hosts =
      get_crdt_pid()
      |> DeltaCrdt.get(key, :infinity)

    {data, hosts}
  end

  @impl true
  @spec handle_init(config()) :: new_data() | {new_data(), timer()}
  def handle_init(config) do
    pooling_interval =
      Map.get(config, :neighbours_sync_interval, @default_neighbours_sync_interval)

    {:ok, crdt_pid} =
      DeltaCrdt.start_link(DeltaCrdt.AWLWWMap,
        sync_interval: Map.get(config, :sync_interval, @default_sync_interval),
        ship_interval: Map.get(config, :ship_interval, @default_ship_interval),
        ship_debounce: Map.get(config, :ship_debounce, @default_ship_debounce)
      )

    :persistent_term.put(__MODULE__, crdt_pid)

    {
      %{crdt_pid: crdt_pid, neighbours_sync_interval: pooling_interval},
      {:set_neighbours_sync, pooling_interval}
    }
  end

  @impl true
  @spec handle_after_init(data()) :: new_data()
  def handle_after_init(%{crdt_pid: crdt_pid} = data) do
    do_set_neighbours(crdt_pid)
    data
  end

  @impl true
  @spec handle_terminate(node(), data()) :: new_data()
  def handle_terminate(_node, %{crdt_pid: crdt_pid} = _data) do
    Logger.debug("#{inspect(__MODULE__)} Handling StateHandoff terminate...")
    :persistent_term.erase(__MODULE__)

    %{crdt_pid: crdt_pid}
  end

  def handle_terminate(node, data) do
    Logger.warning("Invalid terminate state for Node #{inspect(node)}. State: #{inspect(data)}")
  end

  @impl true
  @spec handle_timer(any(), data()) :: new_data() | {new_data(), timer()}
  def handle_timer(
        :set_neighbours_sync,
        %{crdt_pid: crdt_pid, neighbours_sync_interval: pooling_interval} = data
      ) do
    do_set_neighbours(crdt_pid)

    {data, {:set_neighbours_sync, pooling_interval}}
  end

  def handle_timer(_event, data), do: data

  @impl true
  @spec handle_nodeup_event(node(), node_type(), data()) :: new_data()
  def handle_nodeup_event(_node, _node_type, %{crdt_pid: crdt_pid} = _data) do
    do_set_neighbours(crdt_pid)
    %{crdt_pid: crdt_pid}
  end

  @impl true
  @spec handle_nodedown_event(node(), node_type(), data()) :: new_data()
  def handle_nodedown_event(_node, _node_type, %{crdt_pid: crdt_pid} = _data) do
    do_set_neighbours(crdt_pid)
    %{crdt_pid: crdt_pid}
  end

  @impl true
  @spec set(id(), node(), host(), data) :: new_data()
  def set(id, _node, host, %{crdt_pid: _crdt_pid} = data) do
    key = generate_key(id)

    get_crdt_pid()
    |> DeltaCrdt.put(key, [host], :infinity)

    data
  end

  defp do_set_neighbours(this_crdt_pid) do
    nodes = Node.list()

    Logger.debug("Sending :set_neighbours to #{inspect(nodes)} for #{inspect(this_crdt_pid)}")

    neighbours =
      :erpc.multicall(nodes, __MODULE__, :get_crdt_pid, [], @call_timeout)
      |> Enum.map(fn
        {:ok, {:error, node}} ->
          Logger.warning("The node failed to retrieve DeltaCrdt pid -> #{inspect(node)}")

          nil

        {:ok, crdt_pid} ->
          crdt_pid

        error ->
          Logger.warning(
            "Couldn't reach one of the nodes when calling for neighbors -> #{inspect(error)}"
          )

          nil
      end)
      |> Enum.reject(&is_nil/1)

    # add other_node's crdt_pid as a neighbour
    # we are not adding both ways and letting them sync with eachother
    # based on current Node.list() of each node
    DeltaCrdt.set_neighbours(this_crdt_pid, neighbours)
  end
end
