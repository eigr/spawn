defmodule Spawn.Cluster.StateHandoffManager do
  @moduledoc """
  This handles state handoff in a cluster.

  This module monitors node up and down events as well as node terminate events and triggers `Spawn.StateHandoff.Controller.Behaviour` implementations to handle these events.
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
    defstruct data: nil, controller: nil, tag: nil
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

    tag_ref = make_ref()
    %{tag: tag} = ask(%{tag: tag_ref})

    case controller.handle_init(config) do
      {initial_state, timers} ->
        Enum.each(timers, fn {evt, delay} ->
          Process.send_after(self(), {:timer, evt}, delay)
        end)

        {:ok, %State{controller: controller, data: initial_state, tag: tag},
         {:continue, :after_init}}

      initial_state ->
        {:ok, %State{controller: controller, data: initial_state, tag: tag},
         {:continue, :after_init}}
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

  def handle_info(
        {_tag, {:go, ref, {pid, {:clean, [node]}}, _, _}},
        state
      ) do
    new_data = state.controller.handle_terminate(node, state.data)
    send(pid, {ref, new_data})

    {:noreply, ask(%State{state | data: new_data})}
  end

  def handle_info(
        {_tag, {:go, ref, {pid, {:set, [actor_id, host]}}, _, _}},
        state
      ) do
    new_data = state.controller.set(actor_id, Node.self(), host, state.data)

    send(pid, {ref, new_data})

    {:noreply, ask(%State{state | data: new_data})}
  end

  def handle_info(
        {_tag, {:go, ref, {pid, {:get_actor_hosts_by_actor_id, [actor_id]}}, _, _}},
        state
      ) do
    {_new_data, hosts} = state.controller.get_by_id(actor_id, Node.self(), state.data)

    send(pid, {ref, hosts})

    {:noreply, ask(state)}
  end

  def handle_info(event, state) do
    Logger.debug("Received handle_info event #{inspect(event)}")

    {:noreply, state}
  end

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Store a actor and entity in the lookup store
  """
  def set(actor_id, host) do
    spawn(fn -> perform({:set, [actor_id, host]}) end)
  end

  @doc """
  Pickup the stored entity data for a actor
  """
  def get(actor_id) do
    perform({:get_actor_hosts_by_actor_id, [actor_id]})
  end

  @doc """
  Cluster HostActor cleanup
  """
  def clean(node) do
    Logger.debug("Received cleanup action from Node #{inspect(node)}")
    spawn(fn ->
      perform({:clean, [node]})
      Logger.debug("Hosts cleaned for node #{inspect(node)}")
    end)
  end

  # Private functions
  defp do_init(_config) do
    Process.flag(:trap_exit, true)
    Process.flag(:message_queue_data, :off_heap)
    :net_kernel.monitor_nodes(true, node_type: :visible)
  end

  defp ask(%{tag: tag} = state) do
    {:await, ^tag, _} = :sbroker.async_ask_r(Spawn.StateHandoff.Broker, self(), {self(), tag})
    state
  end

  defp perform({action, args} = params) do
    case :sbroker.ask(Spawn.StateHandoff.Broker, {self(), params}) do
      {:go, ref, worker, _, _queue_time} ->
        monitor = Process.monitor(worker)

        receive do
          {^ref, result} ->
            Process.demonitor(monitor, [:flush])
            result

          {:DOWN, ^monitor, _, _, reason} ->
            exit({reason, {__MODULE__, action, args}})
        end

      {:drop, time} ->
        Logger.warning(
          "StateHandoff Manager is overloaded, dropping request #{inspect(params)}, timeout: #{time}"
        )

        []
    end
  end
end
