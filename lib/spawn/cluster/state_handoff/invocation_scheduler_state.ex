defmodule Spawn.Cluster.StateHandoff.InvocationSchedulerState do
  @moduledoc """
  This handles invocation scheduler stream

  It uses the DeltaCrdt library to handle a distributed state, which is an eventually consistent replicated data type.
  The module starts a GenServer that monitors nodes in the cluster, and when a new node comes up it sends a "set_neighbours"
  message to that node's GenServer process with its own DeltaCrdt process ID. This is done to ensure that changes in either node's
  state are reflected across both.
  """
  use GenServer

  require Iter
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config

  @call_timeout 15_000

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent
    }
  end

  @impl true
  def init(_opts) do
    Process.flag(:trap_exit, true)
    Process.flag(:message_queue_data, :off_heap)
    :net_kernel.monitor_nodes(true, node_type: :visible)

    pooling_interval = Config.get(:neighbours_sync_interval)

    {:ok, crdt_pid} =
      DeltaCrdt.start_link(DeltaCrdt.AWLWWMap,
        sync_interval: Config.get(:sync_interval),
        ship_interval: Config.get(:ship_interval),
        ship_debounce: Config.get(:ship_debounce)
      )

    :persistent_term.put(__MODULE__, crdt_pid)

    Process.send_after(self(), :sync, pooling_interval)

    {:ok, crdt_pid, {:continue, :after_init}}
  end

  @impl true
  def handle_continue(:after_init, crdt_pid) do
    do_set_neighbours(crdt_pid)

    {:noreply, crdt_pid}
  end

  def get_crdt_pid do
    :persistent_term.get(__MODULE__, {:error, Node.self()})
  end

  @spec all(node()) :: map()
  def all(node) do
    DeltaCrdt.get(get_crdt_pid(), node, :infinity) || []
  end

  def put_many(invocations) do
    current_mapset = all(Node.self())

    new_mapset =
      Enum.reduce(invocations, current_mapset, fn element, acc ->
        MapSet.put(acc, element)
      end)

    if MapSet.size(current_mapset) != MapSet.size(new_mapset) do
      DeltaCrdt.set(get_crdt_pid(), Node.self(), new_mapset)
    end
  end

  def put(invocation, repeat_in) do
    put_many([{invocation, repeat_in}])
  end

  def remove(node, key) do
    new_mapset =
      Node.self()
      |> all()
      |> MapSet.delete(key)

    DeltaCrdt.set(get_crdt_pid(), Node.self(), new_mapset)
  end

  @impl true
  def terminate(_reason, crdt_pid) do
    Logger.debug("#{inspect(__MODULE__)} Handling InvocationSchedulerState terminate...")
    :persistent_term.erase(__MODULE__)

    {:ok, crdt_pid}
  end

  @impl true
  def handle_info(:sync, crdt_pid) do
    do_set_neighbours(crdt_pid)

    Process.send_after(self(), :sync, Config.get(:neighbours_sync_interval))
    {:noreply, crdt_pid}
  end

  def handle_info({:nodeup, node, node_type}, crdt_pid) do
    Logger.debug("InvocationSchedulerState :nodeup event from #{inspect(node)}")
    do_set_neighbours(crdt_pid)

    {:noreply, crdt_pid}
  end

  def handle_info({:nodedown, node, node_type}, crdt_pid) do
    Logger.debug("InvocationSchedulerState :nodedown event from #{inspect(node)}")

    if Sidecar.GracefulShutdown.running?() do
      take_ownership(node, crdt_pid)
    end

    do_set_neighbours(crdt_pid)

    {:noreply, crdt_pid}
  end

  defp take_ownership(node, crdt_pid) do
    other_node_schedules = all(node)
    my_schedules = all(Node.self())

    DeltaCrdt.set(crdt_pid, Node.self(), other_node_schedules ++ my_schedules)

    Logger.debug(
      "Took ownership of (#{Enum.count(other_node_schedules)}) schedules from node #{inspect(node)}"
    )
  end

  defp do_set_neighbours(this_crdt_pid) do
    nodes = Node.list()

    Logger.notice("Sending :set_neighbours to #{inspect(nodes)} for #{inspect(this_crdt_pid)}")

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
