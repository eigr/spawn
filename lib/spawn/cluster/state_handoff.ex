defmodule Spawn.Cluster.StateHandoff do
  @moduledoc """
  This handles state handoff in a cluster.

  It uses the DeltaCrdt library to handle a distributed state, which is an eventually consistent replicated data type.
  The module starts a GenServer that monitors nodes in the cluster, and when a new node comes up it sends a "set_neighbours"
  message to that node's GenServer process with its own DeltaCrdt process ID. This is done to ensure that changes in either node's
  state are reflected across both.

  The module also handles other messages like "handoff" and "get" to put and retrieve data from the DeltaCrdt state, respectively.
  """

  use GenServer
  require Logger

  @call_timeout 15_000

  @default_sync_interval 5
  @default_ship_interval 5
  @default_ship_debounce 5
  @default_neighbours_sync_interval 60_000

  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def init(opts) do
    Process.flag(:message_queue_data, :off_heap)
    :net_kernel.monitor_nodes(true, node_type: :visible)

    {:ok, crdt_pid} =
      DeltaCrdt.start_link(DeltaCrdt.AWLWWMap,
        sync_interval: Keyword.get(opts, :sync_interval, @default_sync_interval),
        ship_interval: Keyword.get(opts, :ship_interval, @default_ship_interval),
        ship_debounce: Keyword.get(opts, :ship_debounce, @default_ship_debounce)
      )

    Process.send(self(), :set_neighbours, [:noconnect])

    {:ok, crdt_pid}
  end

  @impl true
  def handle_info({:nodeup, node, _node_type}, state) do
    Logger.debug("Received :nodeup event from #{inspect(node)}")

    Process.send(self(), :set_neighbours, [:noconnect])

    {:noreply, state}
  end

  def handle_info({:nodedown, node, _node_type}, state) do
    Logger.debug("Received :nodedown event from #{inspect(node)}")

    Process.send(self(), :set_neighbours, [:noconnect])

    {:noreply, state}
  end

  @impl true
  def handle_info(:set_neighbours, this_crdt_pid) do
    nodes = Node.list()

    Logger.debug("Sending :set_neighbours to #{inspect(nodes)} for #{inspect(this_crdt_pid)}")

    neighbours =
      :erpc.multicall(nodes, __MODULE__, :get_crdt_pid, [])
      |> Enum.map(fn
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

    Process.send_after(self(), :set_neighbours, @default_neighbours_sync_interval)

    {:noreply, this_crdt_pid}
  end

  def handle_call(:get_crdt_pid, _from, this_crdt_pid) do
    {:reply, this_crdt_pid, this_crdt_pid}
  end

  def handle_call({:handoff, actor, hosts}, _from, crdt_pid) do
    DeltaCrdt.put(crdt_pid, actor, hosts)
    {:reply, :ok, crdt_pid}
  end

  def handle_call({:get, actor}, _from, crdt_pid) do
    hosts = DeltaCrdt.get(crdt_pid, actor)
    {:reply, hosts, crdt_pid}
  end

  def handle_call(:get_all_invocations, _from, crdt_pid) do
    invocations =
      crdt_pid
      |> DeltaCrdt.to_map()
      |> Map.values()
      |> List.flatten()
      |> Enum.map(& &1.opts[:invocations])
      # TODO check if this is necessary
      # |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    {:reply, invocations, crdt_pid}
  end

  @impl true
  def handle_call({:clean, node}, _from, crdt_pid) do
    Logger.debug("Received cleanup action from Node #{inspect(node)}")

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

    {:reply, :ok, crdt_pid}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Store a actor and entity in the handoff crdt
  """
  def set(actor, hosts) do
    GenServer.call(__MODULE__, {:handoff, actor, hosts})
  end

  @doc """
  Pickup the stored entity data for a actor
  """
  def get(actor) do
    GenServer.call(__MODULE__, {:get, actor}, @call_timeout)
  end

  def get_crdt_pid do
    GenServer.call(__MODULE__, :get_crdt_pid, @call_timeout)
  end

  def get_all_invocations do
    GenServer.call(__MODULE__, :get_all_invocations, @call_timeout)
  end

  @doc """
  Cluster HostActor cleanup
  """
  def clean(node) do
    GenServer.call(__MODULE__, {:clean, node}, @call_timeout)
  end
end
