defmodule Spawn.Cluster.StateHandoff.Controllers.CrdtController do
  @moduledoc """
  This handles state handoff in a cluster.

  It uses the DeltaCrdt library to handle a distributed state, which is an eventually consistent replicated data type.
  The module starts a GenServer that monitors nodes in the cluster, and when a new node comes up it sends a "set_neighbours"
  message to that node's GenServer process with its own DeltaCrdt process ID. This is done to ensure that changes in either node's
  state are reflected across both.

  The module also handles other messages like "handoff" and "get" to put and retrieve data from the DeltaCrdt state, respectively.
  """
  require Iter
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config
  alias Spawn.Actors.Actor

  import Spawn.Utils.Common, only: [generate_key: 1, actor_host_hash: 0]

  @behaviour Spawn.Cluster.StateHandoff.ControllerBehaviour

  @type node_type :: term()

  @type opts :: Keyword.t()

  @type data :: any()

  @type new_data :: data()

  @type id :: Spawn.Actors.ActorId.t()

  @type host :: Actors.Registry.HostActor.t()

  @type hosts :: list(Actors.Registry.HostActor.t())

  @type timer :: {atom(), integer()}

  @call_timeout 15_000

  def get_crdt_pid do
    :persistent_term.get(__MODULE__, {:error, Node.self()})
  end

  @doc """
  Cluster HostActor cleanup
  """
  @impl true
  def clean(node, %{crdt_pid: crdt_pid} = data) do
    Logger.debug("Received cleanup action from Node #{inspect(node)}")

    keys =
      crdt_pid
      |> DeltaCrdt.to_map()
      |> Iter.filter(fn {_key, [host]} -> host.node == node end)
      |> Iter.map(fn {key, _value} -> key end)

    DeltaCrdt.drop(crdt_pid, keys)

    Logger.debug("Hosts (#{Enum.count(keys)}) cleaned for node #{inspect(node)}")

    data
  end

  @impl true
  @spec get_by_id(id(), data()) :: {new_data(), hosts()}
  def get_by_id(id, %{crdt_pid: crdt_pid} = data) do
    key = generate_key(id)

    hosts =
      case DeltaCrdt.get(crdt_pid, key, :infinity) do
        [host] ->
          [%{host | actor: Actor.decode(host.actor)}]

        nil ->
          []
      end

    {data, hosts}
  end

  @impl true
  @spec handle_init(opts()) :: new_data() | {new_data(), timer()}
  def handle_init(_opts) do
    pooling_interval = Config.get(:neighbours_sync_interval)

    {:ok, crdt_pid} =
      DeltaCrdt.start_link(DeltaCrdt.AWLWWMap,
        sync_interval: Config.get(:sync_interval),
        ship_interval: Config.get(:ship_interval),
        ship_debounce: Config.get(:ship_debounce)
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
    if Sidecar.GracefulShutdown.running?() do
      do_set_neighbours(crdt_pid)
    end

    {data, {:set_neighbours_sync, pooling_interval}}
  end

  def handle_timer(_event, data), do: data

  @impl true
  @spec handle_nodeup_event(node(), node_type(), data()) :: new_data()
  def handle_nodeup_event(_node, _node_type, %{crdt_pid: crdt_pid} = _data) do
    if Sidecar.GracefulShutdown.running?() do
      do_set_neighbours(crdt_pid)
    end

    %{crdt_pid: crdt_pid}
  end

  @impl true
  @spec handle_nodedown_event(node(), node_type(), data()) :: new_data()
  def handle_nodedown_event(node, _node_type, %{crdt_pid: crdt_pid} = _data) do
    if Sidecar.GracefulShutdown.running?() do
      take_ownership(node, crdt_pid)
    end

    do_set_neighbours(crdt_pid)
    %{crdt_pid: crdt_pid}
  end

  @impl true
  @spec set(id(), node(), host(), data) :: new_data()
  def set(id, _node, host, %{crdt_pid: crdt_pid} = data) do
    key = generate_key(id)

    host = %{host | actor: Actor.encode(host.actor)}

    DeltaCrdt.put(crdt_pid, key, [host], :infinity)

    data
  end

  defp take_ownership(node, crdt_pid) do
    Logger.debug(" #{inspect(node)}")

    registers =
      crdt_pid
      |> DeltaCrdt.to_map()
      |> Iter.filter(fn {_key, [host]} ->
        host.node == node and Keyword.get(host.opts, :hash) == actor_host_hash()
      end)
      |> Iter.map(fn {key, [value]} -> {key, [%{value | node: Node.self()}]} end)
      |> Iter.into(%{})

    DeltaCrdt.merge(crdt_pid, registers)

    Logger.debug(
      "Took ownership of (#{Enum.count(registers)}) registers from node #{inspect(node)}"
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
