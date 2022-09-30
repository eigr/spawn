defmodule Actors.Registry.ActorRegistry do
  @moduledoc false
  use GenServer
  require Logger

  alias Actors.Registry.ActorNode
  alias Phoenix.PubSub

  @topic "actors"

  def child_spec(state \\ %{}) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [state]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  @impl true
  def init(state) do
    :ok = PubSub.subscribe(:actor_channel, @topic)
    :ok = :net_kernel.monitor_nodes(true, node_type: :visible)

    {:ok, state, {:continue, :join_cluster}}
  end

  @impl true
  def handle_continue(:join_cluster, state) do
    PubSub.broadcast(
      :actor_channel,
      @topic,
      {:join, %{node: node()}}
    )

    {:noreply, state}
  end

  @impl true
  def handle_call({:get, _system_name, actor_name}, from, state) do
    spawn(fn ->
      state
      |> Enum.reduce([], fn {key, values}, acc ->
        values = Map.delete(values, :__struct__)
        opts = Map.get(state, :opts)

        Enum.map(values, fn {actor_key, actor} ->
          if actor_key == actor_name do
            [%{node: key, actor: %ActorNode{actors: [actor]}, opts: opts}] ++ acc
          else
            [] ++ acc
          end
        end)
      end)
      |> List.flatten()
      |> Enum.uniq()
      |> List.first()
      |> then(fn
        nil ->
          GenServer.reply(from, {:not_found, []})

        first_node_found ->
          GenServer.reply(from, {:ok, first_node_found})
      end)
    end)

    {:noreply, state}
  end

  def handle_call({:get_all, system_name}, from, state) do
    spawn(fn ->
      nodes =
        state
        |> Enum.reduce([], fn {key, %ActorNode{actors: actors, opts: opts} = _value}, acc ->
          Enum.map(actors, fn actor ->
            if actor.actor_system.name == system_name do
              [%{node: key, actor: %ActorNode{actors: [actor], opts: opts}}] ++ acc
            else
              [] ++ acc
            end
          end)
        end)
        |> List.flatten()
        |> Enum.uniq()

      reply =
        if Enum.all?(nodes, &is_nil/1) do
          {:not_found, []}
        else
          {:ok, nodes}
        end

      GenServer.reply(from, reply)
    end)

    {:noreply, state}
  end

  def handle_call(
        {:register, %ActorNode{actors: _node_actors, opts: opts} = actor_node},
        _from,
        state
      ) do
    node = Node.self()
    new_state = include_entities(state, %{node => actor_node})

    # send new entities of this node to all connected nodes
    PubSub.broadcast(
      :actor_channel,
      @topic,
      {:incoming_actors, %{node => actor_node}}
    )

    {:reply, new_state, new_state}
  end

  @impl true
  def handle_info({:incoming_actors, node_actors}, state) do
    {:noreply, include_entities(state, node_actors)}
  end

  def handle_info({:join, %{node: node}}, state) do
    Logger.notice(fn -> "Got Node join from #{inspect(node)} sending current state" end)

    :ok =
      PubSub.direct_broadcast(
        node,
        :actor_channel,
        @topic,
        {:incoming_actors, Map.take(state, [node()])}
      )

    {:noreply, state}
  end

  def handle_info({:nodeup, _node, _node_type}, state) do
    {:noreply, state}
  end

  def handle_info({:nodedown, node, _node_type}, state) do
    Logger.debug(fn -> "Received :nodedown from #{node} rebalancing registred entities" end)

    new_state = if Map.has_key?(state, node), do: %{state | node => []}, else: state

    {:noreply, new_state}
  end

  def handle_info({:leave, %{node: node}}, state) do
    Logger.debug(fn -> "Received :leave from #{node} rebalancing registred entities" end)

    new_state = if Map.has_key?(state, node), do: %{state | node => []}, else: state

    {:noreply, new_state}
  end

  @impl true
  def terminate(_reason, _state) do
    node = Node.self()

    PubSub.broadcast(
      :actor_channel,
      @topic,
      {:leave, %{node: node}}
    )
  end

  def start_link(args) do
    # note the change here in providing a name: instead of [] as the 3rd param
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  # register entities to the service
  def register(node_actor) do
    GenServer.call(__MODULE__, {:register, node_actor})
  end

  # fetch current entities of the service
  def lookup(system_name) do
    GenServer.call(__MODULE__, {:get_all, system_name})
  end

  def lookup(system_name, actor_name) do
    GenServer.call(__MODULE__, {:get, system_name, actor_name})
  end

  defp include_entities(state, node_actors) do
    if state == %{} && node_actors == %{} do
      node_actors
    else
      merge =
        Enum.reduce(state, node_actors, fn m, acc ->
          {k, v} = m

          %{actors: actors} = Map.get(acc, k)
          Map.put(state, k, Map.merge(actors, v))
        end)

      Map.delete(merge, :__struct__)
    end
  end
end
