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

  @default_sync_interval 2
  @default_ship_interval 2
  @default_ship_debounce 2
  @default_neighbours_sync_interval 60_000

  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent
    }
  end

  @impl true
  def init(config) do
    Process.flag(:trap_exit, true)
    :net_kernel.monitor_nodes(true, node_type: :visible)

    {:ok, crdt_pid} =
      DeltaCrdt.start_link(DeltaCrdt.AWLWWMap,
        sync_interval: Map.get(config, :sync_interval, @default_sync_interval),
        ship_interval: Map.get(config, :ship_interval, @default_ship_interval),
        ship_debounce: Map.get(config, :ship_debounce, @default_ship_debounce)
      )

    :persistent_term.put(__MODULE__, crdt_pid)

    Process.send_after(
      self(),
      :set_neighbours_sync,
      Map.get(config, :neighbours_sync_interval, @default_neighbours_sync_interval)
    )

    {:ok, crdt_pid, {:continue, :after_init}}
  end

  @impl true
  def handle_continue(:after_init, crdt_pid) do
    do_set_neighbours(crdt_pid)

    {:noreply, crdt_pid}
  end

  @impl true
  def terminate(_reason, crdt_pid) do
    Logger.debug("Calling StateHandoff terminate")

    :persistent_term.erase(__MODULE__)

    {:ok, crdt_pid}
  end

  @impl true
  def handle_info(:set_neighbours_sync, this_crdt_pid) do
    do_set_neighbours(this_crdt_pid)

    Process.send_after(self(), :set_neighbours_sync, @default_neighbours_sync_interval)

    {:noreply, this_crdt_pid}
  end

  def handle_info({:nodeup, node, _node_type}, this_crdt_pid) do
    Logger.debug("Received :nodeup event from #{inspect(node)}")

    do_set_neighbours(this_crdt_pid)

    {:noreply, this_crdt_pid}
  end

  def handle_info({:nodedown, node, _node_type}, this_crdt_pid) do
    Logger.debug("Received :nodedown event from #{inspect(node)}")

    do_set_neighbours(this_crdt_pid)

    {:noreply, this_crdt_pid}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Store a actor and entity in the handoff crdt
  """
  def set(actor, hosts) do
    get_crdt_pid()
    |> DeltaCrdt.put(actor, hosts, :infinity)
  end

  @doc """
  Pickup the stored entity data for a actor
  """
  def get(actor) do
    get_crdt_pid()
    |> DeltaCrdt.get(actor, :infinity)
  end

  def get_crdt_pid do
    :persistent_term.get(__MODULE__, {:error, Node.self()})
  end

  def get_all_invocations do
    get_crdt_pid()
    |> DeltaCrdt.to_map()
    |> Map.values()
    |> List.flatten()
    |> Enum.map(& &1.opts[:invocations])
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  @doc """
  Cluster HostActor cleanup
  """
  def clean(node) do
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
