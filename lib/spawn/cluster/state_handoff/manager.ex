defmodule Spawn.Cluster.StateHandoff.Manager do
  @moduledoc """
  This handles state handoff in a cluster.

  This module monitors node up and down events as well as node terminate events and triggers `Spawn.Cluster.StateHandoff.ControllerBehaviour` implementations to handle these events.
  """
  use GenServer
  require Logger

  def child_spec(id, opts \\ []) do
    %{
      id: id,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent
    }
  end

  defmodule State do
    defstruct data: nil, controller: nil, timer: nil
  end

  @impl true
  def init(config) do
    controller =
      Application.get_env(
        :spawn,
        :state_handoff_controller_adapter,
        Spawn.Cluster.StateHandoff.Controllers.PersistentController
      )

    do_init(config)

    case controller.handle_init(config) do
      {initial_state, {evt, delay} = _scheduler} ->
        timer = Process.send_after(self(), {:timer, evt}, delay)

        {:ok, %State{controller: controller, data: initial_state, timer: timer},
         {:continue, :after_init}}

      initial_state ->
        {:ok, %State{controller: controller, data: initial_state}, {:continue, :after_init}}
    end
  end

  @impl true
  def handle_continue(:after_init, %State{controller: controller, data: data} = state) do
    new_data = controller.handle_after_init(data)

    {:noreply, %State{state | data: new_data}}
  end

  @impl true
  def terminate(_reason, %State{controller: controller, data: data} = state) do
    Logger.debug("Calling StateHandoff Manager terminate")
    node = Node.self()
    new_data = controller.handle_terminate(node, data)

    {:ok, %State{state | data: new_data}}
  end

  @impl true
  def handle_cast({:set, actor_id, host}, state) do
    new_data = state.controller.set(actor_id, Node.self(), host, state.data)

    {:noreply, %State{state | data: new_data}}
  end

  @impl true
  def handle_call({:get_actor_hosts_by_actor_id, actor_id}, _from, state) do
    {_new_data, hosts} = state.controller.get_by_id(actor_id, state.data)

    {:reply, hosts, state}
  end

  def handle_call({:clean, node}, _from, state) do
    new_data = state.controller.handle_terminate(node, state.data)

    {:reply, new_data, %State{state | data: new_data}}
  end

  @impl true
  def handle_info(
        {:timer, event},
        %State{controller: controller, data: data, timer: timer} = state
      ) do
    if !is_nil(timer) do
      Process.cancel_timer(timer)
    end

    case controller.handle_timer(event, data) do
      {new_data, {evt, delay} = _timer} ->
        new_timer = Process.send_after(self(), {:timer, evt}, delay)
        {:noreply, %State{state | data: new_data, timer: new_timer}}

      new_data ->
        {:noreply, %State{state | data: new_data}}
    end
  end

  def handle_info({:nodeup, node, node_type}, %State{controller: controller, data: data} = state) do
    Logger.debug("Received :nodeup event from #{inspect(node)}")
    new_data = controller.handle_nodeup_event(node, node_type, data)

    {:noreply, %State{state | data: new_data}}
  end

  def handle_info(
        {:nodedown, node, node_type},
        %State{controller: controller, data: data} = state
      ) do
    Logger.debug("Received :nodedown event from #{inspect(node)}")
    new_data = controller.handle_nodedown_event(node, node_type, data)

    {:noreply, %State{state | data: new_data}}
  end

  def handle_info(event, state) do
    Logger.debug("Received handle_info event #{inspect(event)}")

    {:noreply, state}
  end

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Store a actor and entity in the lookup store
  """
  def set(actor_id, host), do: GenServer.cast(__MODULE__, {:set, actor_id, host})

  @doc """
  Pickup the stored entity data for a actor
  """
  def get(actor_id),
    do: GenServer.call(__MODULE__, {:get_actor_hosts_by_actor_id, actor_id}, :infinity)

  @doc """
  Cluster HostActor cleanup
  """
  def clean(node) do
    Logger.debug("Received cleanup action from Node #{inspect(node)}")

    GenServer.call(__MODULE__, {:clean, node})

    Logger.debug("Hosts cleaned for node #{inspect(node)}")
  end

  # Private functions
  defp do_init(_config) do
    Process.flag(:trap_exit, true)
    Process.flag(:message_queue_data, :off_heap)
    :net_kernel.monitor_nodes(true, node_type: :visible)
  end
end
