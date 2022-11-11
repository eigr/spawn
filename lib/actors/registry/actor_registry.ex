defmodule Actors.Registry.ActorRegistry do
  @moduledoc false
  use GenServer
  require Logger

  alias Actors.Registry.{HostActor, LoadBalancer}
  alias Eigr.Functions.Protocol.Actors.{Actor, ActorId}
  alias Spawn.Cluster.StateHandoff

  @call_timeout 15_000

  def child_spec(state \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [state]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    Process.flag(:message_queue_data, :off_heap)
    :ok = :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, state}
  end

  @impl true
  def handle_info({:nodeup, node, _node_type}, state) do
    Logger.debug("Received :nodeup event from #{inspect(node)}")

    {:noreply, state}
  end

  def handle_info({:nodedown, node, _node_type}, state) do
    Logger.debug("Received :nodedown event from #{inspect(node)}")
    {:noreply, state}
  end

  @impl true
  def handle_call({:get, _system_name, actor_name}, from, state) do
    spawn(fn ->
      case StateHandoff.get(actor_name) do
        nil ->
          GenServer.reply(from, {:not_found, []})

        hosts ->
          Enum.filter(hosts, fn ac -> ac.actor.id.name == actor_name end)
          |> then(fn
            [] ->
              GenServer.reply(from, {:not_found, []})

            hosts ->
              case LoadBalancer.next_host(hosts) do
                {:ok, node_host, updated_hosts} ->
                  StateHandoff.set(actor_name, updated_hosts)
                  GenServer.reply(from, {:ok, node_host})

                _ ->
                  GenServer.reply(from, {:not_found, []})
              end
          end)
      end
    end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:get_hosts_by_actor, _system_name, actor_name}, from, state) do
    spawn(fn ->
      case StateHandoff.get(actor_name) do
        nil ->
          GenServer.reply(from, {:not_found, []})

        hosts ->
          Enum.filter(hosts, fn ac -> ac.actor.id.name == actor_name end)
          |> then(fn
            [] ->
              GenServer.reply(from, {:not_found, []})

            hosts ->
              GenServer.reply(from, {:ok, hosts})
          end)
      end
    end)

    {:noreply, state}
  end

  def handle_call({:register, hosts}, _from, state) do
    Enum.each(hosts, fn %HostActor{
                          node: node,
                          actor: %Actor{id: %ActorId{name: name} = _id} = _actor
                        } = host ->
      case StateHandoff.get(name) do
        nil ->
          StateHandoff.set(name, [host])

        hosts ->
          filtered_list =
            Enum.filter(hosts, fn ac -> ac.node == node and ac.actor.id.name == name end)

          if length(filtered_list) <= 0 do
            updated_hosts = hosts ++ [host]
            StateHandoff.set(name, updated_hosts)
          end
      end
    end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:register_invocation_request, actor, request}, state) do
    actor
    |> StateHandoff.get()
    |> Kernel.||([])
    |> Enum.map(fn host ->
      invocations = (host.opts[:invocations] || []) ++ [request]

      opts = Keyword.put(host.opts, :invocations, invocations)
      %{host | opts: opts}
    end)
    |> then(fn
      [] ->
        :nothing

      updated_hosts ->
        StateHandoff.set(actor, updated_hosts)
    end)

    {:noreply, state}
  end

  def handle_cast({:remove_invocation_request, actor, request}, state) do
    actor
    |> StateHandoff.get()
    |> Kernel.||([])
    |> Enum.map(fn host ->
      invocations = host.opts[:invocations] || []
      invocation = Enum.find(invocations, &(&1 == request))
      invocations = invocations -- [invocation]

      opts = Keyword.put(host.opts, :invocations, invocations)
      %{host | opts: opts}
    end)
    |> then(fn
      [] ->
        :nothing

      updated_hosts ->
        StateHandoff.set(actor, updated_hosts)
    end)

    {:noreply, state}
  end

  @impl true
  def terminate(_reason, _state) do
    Logger.debug("Stopping ActorRegistry...")
    StateHandoff.clean(Node.self())
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Register `member` entities to the ActorRegistry.
  Returns `Cluster` with all Host members.
  ## Examples
      iex> hosts = [%HostActor{node: Node.self(), actor: actor, opts: []}}]
      iex> ActorRegistry.register(hosts)
      :ok
  """
  @doc since: "0.1.0"
  @spec register(list(HostActor.t())) :: :ok
  def register(hosts) do
    GenServer.call(__MODULE__, {:register, hosts}, @call_timeout)
  end

  @doc """
  Get all invocations stored for actor
  ## Examples
      iex> ActorRegistry.get_all_invocations()
      [<<10, 14, 10, 12, 115, 112>>]
  """
  def get_all_invocations do
    StateHandoff.get_all_invocations()
  end

  def remove_invocation_request(actor, invocation_request) do
    GenServer.cast(__MODULE__, {:remove_invocation_request, actor, invocation_request})
  end

  def register_invocation_request(actor, invocation_request) do
    GenServer.cast(__MODULE__, {:register_invocation_request, actor, invocation_request})
  end

  @doc """
  Fetch current entities of the service.
  Returns `Member` with Host and specific actor.
  ## Examples
      iex> ActorRegistry.lookup("spawn-system", "joe")
      {:ok,
       %Actors.Registry.Member{
         id: :"spawn_a2@127.0.0.1",
         host_function: %Actors.Registry.HostActor{
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
               deactivation_strategy: %Eigr.Functions.Protocol.Actors.ActorDeactivationStrategy{
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
           opts: []
         }
      }}
  """
  @doc since: "0.1.0"
  @spec lookup(String.t(), String.t()) :: {:ok, Member.t()} | {:not_found, []}
  def lookup(system_name, actor_name) do
    GenServer.call(__MODULE__, {:get, system_name, actor_name})
  end

  @spec get_hosts_by_actor(String.t(), String.t()) :: {:ok, Member.t()} | {:not_found, []}
  def get_hosts_by_actor(system_name, actor_name) do
    GenServer.call(__MODULE__, {:get_hosts_by_actor, system_name, actor_name})
  end
end
