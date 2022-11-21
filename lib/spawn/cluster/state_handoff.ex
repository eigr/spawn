defmodule Spawn.Cluster.StateHandoff do
  @moduledoc false
  use GenServer
  require Logger

  @call_timeout 15_000

  @default_sync_interval 5
  @default_ship_interval 5
  @default_ship_debounce 5

  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def init(opts) do
    {:ok, crdt_pid} =
      DeltaCrdt.start_link(DeltaCrdt.AWLWWMap,
        sync_interval: Keyword.get(opts, :sync_interval, @default_sync_interval),
        ship_interval: Keyword.get(opts, :ship_interval, @default_ship_interval),
        ship_debounce: Keyword.get(opts, :ship_debounce, @default_ship_debounce)
      )

    {:ok, crdt_pid}
  end

  # other_node is actually a tuple { __MODULE__, other_node } passed from above,
  #  by using that in GenServer.call we are sending a message to the process
  #  named __MODULE__ on other_node
  @impl true
  def handle_call({:set_neighbours, other_node}, _from, this_crdt_pid) do
    Logger.debug(
      "Sending :set_neighbours to #{inspect(other_node)} with #{inspect(this_crdt_pid)}"
    )

    # pass our crdt pid in a message so that the crdt on other_node can add it as a neighbour
    # expect other_node to send back it's crdt_pid in response
    other_crdt_pid = GenServer.call(other_node, {:fulfill_set_neighbours, this_crdt_pid})
    # add other_node's crdt_pid as a neighbour, we need to add both ways so changes in either
    # are reflected across, otherwise it would be one way only
    DeltaCrdt.set_neighbours(this_crdt_pid, [other_crdt_pid])

    {:reply, :ok, this_crdt_pid}
    # catch
    #  :exit, {:noproc, _} = error ->
    #    Logger.error("Error during node #{inspect(other_node)} sync. Error: #{inspect(error)}")
    #    raise error
  end

  # the above GenServer.call ends up hitting this callback, but importantly this
  #  callback will run in the other node that was originally being connected to
  def handle_call({:fulfill_set_neighbours, other_crdt_pid}, _from, this_crdt_pid) do
    Logger.debug("Adding neighbour #{inspect(other_crdt_pid)} to this #{inspect(this_crdt_pid)}")
    # add the crdt's as a neighbour, pass back our crdt to the original adding node via a reply
    DeltaCrdt.set_neighbours(this_crdt_pid, [other_crdt_pid])
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
    schedules =
      crdt_pid
      |> DeltaCrdt.to_map()
      |> Map.values()
      |> List.flatten()
      |> Enum.map(& &1.opts[:invocations])
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    {:reply, schedules, crdt_pid}
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

    # clean all actors
    DeltaCrdt.drop(crdt_pid, Map.keys(actors))

    # overwrite with correct set of hosts
    DeltaCrdt.merge(crdt_pid, new_hosts)

    Logger.debug("Hosts cleaned for node #{inspect(node)}")

    {:reply, :ok, crdt_pid}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # join this crdt with one on another node by adding it as a neighbour
  def join(other_node) do
    # the second element of the tuple, { __MODULE__, node } is a syntax that
    #  identifies the process named __MODULE__ running on the other node other_node
    Logger.debug("Joining StateHandoff at #{inspect(other_node)}")
    GenServer.call(__MODULE__, {:set_neighbours, {__MODULE__, other_node}})
  end

  # store a actor and entity in the handoff crdt
  def set(actor, hosts) do
    GenServer.call(__MODULE__, {:handoff, actor, hosts})
  end

  # pickup the stored entity data for a actor
  def get(actor) do
    GenServer.call(__MODULE__, {:get, actor}, @call_timeout)
  end

  def get_all_invocations do
    GenServer.call(__MODULE__, :get_all_invocations, @call_timeout)
  end

  def clean(node) do
    GenServer.call(__MODULE__, {:clean, node}, @call_timeout)
  end
end
