defmodule Spawn.Registry.ActorRegistry do
  @moduledoc false
  use GenServer
  require Logger

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

    Logger.debug("Initializing Actor Registry with state #{inspect(state)}")

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
  def handle_cast({:register, new_entities}, state) do
    # convert initial state to map if empty list
    # Accumulate new entities for the node key
    new_state =
      Enum.reduce(new_entities, state, fn entity, acc ->
        acc_entity = Map.get(acc, entity.node)

        entities =
          case acc_entity do
            nil -> [entity]
            _ -> [entity] ++ Map.get(acc, entity.node)
          end

        Map.put(acc, entity.node, entities)
      end)

    # send new entities of this node to all connected nodes
    node = Node.self()

    PubSub.broadcast(
      :actor_channel,
      @topic,
      {:incoming_actors, %{node => new_entities}}
    )

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:get, entity_type, service_name, method_name}, _from, state) do
    nodes =
      state
      |> Enum.reduce([], fn {key, value}, acc ->
        for entity <- value do
          if entity.entity_type == entity_type and entity.service_name == service_name do
            service_data =
              Enum.map(entity.services, fn service ->
                if service.name == get_simple_name(service_name) do
                  method_metadata =
                    Enum.map(service.methods, fn method ->
                      if method.name == method_name do
                        %{
                          entity_type: entity_type,
                          service_name: get_simple_name(service_name),
                          full_service_name: service_name,
                          persistence_id: entity.persistence_id,
                          method_name: method.name,
                          method: method
                        }
                      else
                        %{}
                      end
                    end)
                    |> List.flatten()
                    |> Enum.uniq()
                    |> List.first()

                  method_metadata
                else
                  %{}
                end
              end)
              |> List.flatten()
              |> Enum.uniq()

            [%{node: key, entity: service_data}] ++ acc
          end
        end
      end)
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    if Enum.all?(nodes, &is_nil/1) do
      {:reply, [], state}
    else
      {:reply, nodes, state}
    end
  end

  @impl true
  def handle_info({:incoming_actors, message}, state) do
    self = Node.self()

    if Map.has_key?(message, self) do
      Logger.debug("Ignoring Actor join of Node: [#{inspect(Node.self())}]")
      {:noreply, state}
    else
      Logger.debug("New Actor join. Actor: #{inspect(message)}")
      {:noreply, include_entities(state, message)}
    end
  end

  def handle_info({:join, %{node: node}}, state) do
    Logger.debug(fn -> "Got Node join from #{inspect(node)} sending current state" end)

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
    # Ignore :nodeup as we are expecting a :join message before sending a reply
    # with the current state
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, node, _node_type}, state) do
    Logger.debug(fn -> "Received :nodedown from #{node} rebalancing registred entities" end)

    new_state = if Map.has_key?(state, node), do: %{state | node => []}, else: state

    {:noreply, new_state}
  end

  @impl true
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
  def register(_args, entities) do
    GenServer.cast(__MODULE__, {:register, entities})
  end

  # fetch current entities of the service
  def lookup(entity_type, service_name, method_name) do
    GenServer.call(__MODULE__, {:get, entity_type, service_name, method_name})
  end

  defp include_entities(state, message), do: Map.merge(state, message)

  defp get_simple_name(service_name), do: String.split(service_name, ".") |> List.last()
end
