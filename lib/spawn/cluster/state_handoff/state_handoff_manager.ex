defmodule Spawn.Cluster.StateHandoffManager do
  @moduledoc """
  This handles state handoff in a cluster.

  This module monitors node up and down events as well as node terminate events and triggers `Spawn.StateHandoff.Controller.Behaviour` implementations to handle these events.
  """
  use GenServer
  require Logger

  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent
    }
  end

  defmodule State do
    defstruct data: nil, controller: nil
  end

  @impl true
  def init(config) do
    controller =
      Application.get_env(
        :spawn,
        :state_handoff_controller_adapter,
        Spawn.Cluster.StateHandoffPersistentController
      )

    do_init(config)

    case controller.handle_init(config) do
      {initial_state, timers} ->
        Enum.each(timers, fn {evt, delay} ->
          Process.send_after(self(), {:timer, evt}, delay)
        end)

        {:ok, %State{controller: controller, data: initial_state}, {:continue, :after_init}}

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
  def handle_call(
        {:get_actor_hosts_by_actor_id, actor_id},
        from,
        %State{controller: controller, data: data} = state
      ) do
    async_get_actors(controller, from, actor_id, data)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:clean, node}, %State{controller: controller, data: data} = state) do
    new_data = controller.handle_terminate(node, data)
    {:noreply, %State{state | data: new_data}}
  end

  def handle_cast({:set, actor_id, host}, %State{controller: controller, data: data} = state) do
    node = Node.self()
    new_data = controller.set(actor_id, node, host, data)
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
  def handle_info({:timer, event}, %State{controller: controller, data: data} = state) do
    case controller.handle_timer(event, data) do
      {new_data, {evt, delay} = _timer} ->
        Process.send_after(self(), {:timer, evt}, delay)
        {:noreply, %State{state | data: new_data}}

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
  def get(actor_id), do: GenServer.call(__MODULE__, {:get_actor_hosts_by_actor_id, actor_id})

  @doc """
  Cluster HostActor cleanup
  """
  def clean(node) do
    Logger.debug("Received cleanup action from Node #{inspect(node)}")
    GenServer.cast(__MODULE__, {:clean, node})
    Logger.debug("Hosts cleaned for node #{inspect(node)}")
  end

  # Private functions
  defp do_init(_config) do
    Process.flag(:trap_exit, true)
    Process.flag(:message_queue_data, :off_heap)
    :net_kernel.monitor_nodes(true, node_type: :visible)
  end

  defp async_get_actors(controller, from, id, data) do
    node = Node.self()

    spawn(fn ->
      {_new_data, hosts} = controller.get_by_id(id, node, data)
      GenServer.reply(from, hosts)
    end)
  end
end
