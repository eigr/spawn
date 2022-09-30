defmodule Actors.Registry.ActorRegistry do
  @moduledoc false
  use GenServer
  require Logger

  alias Actors.Registry.{Cluster, Host, Member}
  alias Phoenix.PubSub

  @topic "actors"

  def child_spec(
        state \\ %Cluster{
          members: [
            %Member{
              id: Node.self(),
              host_function: %Host{actors: [], opts: []}
            }
          ]
        }
      ) do
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
  def handle_continue(:join_cluster, %Cluster{members: members} = state) do
    me =
      members
      |> Enum.uniq()
      |> List.first()

    PubSub.broadcast(
      :actor_channel,
      @topic,
      {:join, me}
    )

    {:noreply, state}
  end

  @impl true
  def handle_info({:join, %Member{id: node} = member}, %Cluster{} = state) do
    Logger.notice(fn -> "Got Node join from #{inspect(node)} sending current state" end)

    :ok =
      PubSub.direct_broadcast(
        node,
        :actor_channel,
        @topic,
        {:incoming_actors, member}
      )

    {:noreply, state}
  end

  def handle_info({:incoming_actors, member}, %Cluster{} = state) do
    {:noreply, include_entities(state, member)}
  end

  def handle_info({:nodeup, _node, _node_type}, %Cluster{} = state) do
    {:noreply, state}
  end

  def handle_info({:nodedown, node, _node_type}, %Cluster{members: members} = state) do
    Logger.debug(fn -> "Received :nodedown from #{node} rebalancing registred entities" end)

    node_member =
      members
      |> Enum.filter(fn member -> member.id == node end)
      |> List.first()

    new_members = List.delete(members, node_member)

    new_state = %Cluster{state | members: new_members}

    {:noreply, new_state}
  end

  def handle_info({:leave, %{node: node}}, %Cluster{members: members} = state) do
    Logger.debug(fn -> "Received :leave from #{node} rebalancing registred entities" end)

    node_member =
      members
      |> Enum.filter(fn member -> member.id == node end)
      |> List.first()

    new_members = List.delete(members, node_member)

    new_state = %Cluster{state | members: new_members}

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:get, _system_name, actor_name}, from, %Cluster{members: members} = state) do
    spawn(fn ->
      members
      |> Enum.reduce([], fn member, acc ->
        opts = member.host_function.opts
        actors = member.host_function.actors

        Enum.map(actors, fn actor ->
          if actor.name == actor_name do
            [%Member{id: member.id, host_function: %Host{actors: [actor], opts: opts}}] ++ acc
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

  def handle_call({:register, %Member{} = member}, _from, state) do
    new_state = include_entities(state, member)

    # send new entities of this node to all connected nodes
    PubSub.broadcast(
      :actor_channel,
      @topic,
      {:incoming_actors, member}
    )

    {:reply, new_state, new_state}
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
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Register `member` entities to the ActorRegistry.

  Returns `Cluster` with all Host members.

  ## Examples

      iex> member = %Member{id: Node.self(), host_function: %Host{actors: [], opts: []}}
      iex> ActorRegistry.register(member)
      %Cluster{
          members: [
            %Member{
              id: Node.self(),
              host_function: %Host{actors: [], opts: []}
            }
          ]
        }

  """
  @doc since: "0.1.0"
  @spec register(Member.t()) :: Cluster.t()
  def register(member) do
    GenServer.call(__MODULE__, {:register, member})
  end

  @doc """
  Fetch current entities of the service.

  Returns `Member` with Host and specific actor.

  ## Examples

      iex> ActorRegistry.lookup("spawn-system", "joe")
      {:ok,
       %Actors.Registry.Member{
         id: :"spawn_a2@127.0.0.1",
         host_function: %Actors.Registry.Host{
           actors: [
             %Eigr.Functions.Protocol.Actors.Actor{
               name: "jose",
               persistent: true,
               state: %Eigr.Functions.Protocol.Actors.ActorState{
                 tags: %{},
                 state: nil,
                 __unknown_fields__: []
               },
               snapshot_strategy: %Eigr.Functions.Protocol.Actors.ActorSnapshotStrategy{
                 strategy: {:timeout,
                   %Eigr.Functions.Protocol.Actors.TimeoutStrategy{
                     timeout: 2000,
                     __unknown_fields__: []
                   }},
                 __unknown_fields__: []
               },
               deactivate_strategy: %Eigr.Functions.Protocol.Actors.ActorDeactivateStrategy{
                 strategy: {:timeout,
                   %Eigr.Functions.Protocol.Actors.TimeoutStrategy{
                     timeout: 30000,
                     __unknown_fields__: []
                   }},
                 __unknown_fields__: []
               },
               __unknown_fields__: []
             }
           ],
           opts: [host_interface: SpawnSdk.Interface]
         }
      }}
  """
  @doc since: "0.1.0"
  @spec lookup(String.t(), String.t()) :: {:ok, Member.t()} | {:not_found, []}
  def lookup(system_name, actor_name) do
    GenServer.call(__MODULE__, {:get, system_name, actor_name})
  end

  defp include_entities(state, incoming_member) do
    members = Map.get(state, :members)

    actual_host_member =
      Enum.filter(members, fn m ->
        m.id == incoming_member.id
      end)
      |> Enum.uniq()
      |> List.first()

    actual_opts = actual_host_member.host_function.opts
    actual_actors = actual_host_member.host_function.actors

    incoming_opts = incoming_member.host_function.opts
    incoming_actors = incoming_member.host_function.actors

    new_actor_list = actual_actors ++ incoming_actors
    new_opts = Keyword.merge(actual_opts, incoming_opts)

    new_member = %{
      actual_host_member
      | host_function: %Host{actors: new_actor_list, opts: new_opts}
    }

    new_members =
      Enum.map(members, fn member ->
        if member.id == new_member.id, do: new_member, else: member
      end)

    %{state | members: new_members}
  end
end
