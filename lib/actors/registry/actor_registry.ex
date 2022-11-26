defmodule Actors.Registry.ActorRegistry do
  @moduledoc false
  require Logger

  alias Actors.Registry.{HostActor, LoadBalancer}
  alias Eigr.Functions.Protocol.Actors.{Actor, ActorId}
  alias Spawn.Cluster.StateHandoff

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
    Enum.each(hosts, fn %HostActor{
                          node: _node,
                          actor: %Actor{id: %ActorId{name: name} = _id} = _actor
                        } = host ->
      case StateHandoff.get(name) do
        nil ->
          StateHandoff.set(name, [host])

        hosts ->
          updated_hosts = hosts ++ [host]
          StateHandoff.set(name, updated_hosts)
      end
    end)
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

  def remove_invocation_request(actor, request) do
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
  end

  def register_invocation_request(actor, request) do
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
  end

  @doc """
  Fetch current entities of the service.
  Returns `HostActor` with Host and specific actor.
  """
  @doc since: "0.1.0"
  @spec lookup(String.t(), String.t(), Keyword.t()) :: {:ok, HostActor.t()} | {:not_found, []}
  def lookup(_system_name, actor_name, opts \\ []) do
    case StateHandoff.get(actor_name) do
      nil ->
        {:not_found, []}

      state_hosts ->
        filter_by_parent? = Keyword.get(opts, :filter_by_parent, false)
        parent_name = Keyword.fetch!(opts, :parent)

        case filter_by_parent? do
          true ->
            Enum.filter(state_hosts, fn ac ->
              ac.actor.id.parent == parent_name
            end)

          _ ->
            Enum.filter(state_hosts, fn ac -> ac.actor.id.name == actor_name end)
        end
        |> then(fn
          [] ->
            {:not_found, []}

          hosts ->
            if filter_by_parent? do
              %HostActor{node: _node, actor: actor, opts: opts} = host = Enum.random(hosts)
              new_actor = %Actor{actor | id: %ActorId{actor.id | name: parent_name}}
              {:ok, %HostActor{host | actor: new_actor, opts: opts}}
            else
              case LoadBalancer.next_host(hosts) do
                {:ok, node_host, updated_hosts} ->
                  StateHandoff.set(actor_name, updated_hosts)
                  {:ok, node_host}

                _ ->
                  {:not_found, []}
              end
            end
        end)
    end
  end

  @spec get_hosts_by_actor(String.t(), String.t()) :: {:ok, Member.t()} | {:not_found, []}
  def get_hosts_by_actor(_system_name, actor_name) do
    case StateHandoff.get(actor_name) do
      nil ->
        {:not_found, []}

      hosts ->
        Enum.filter(hosts, fn ac -> ac.actor.id.name == actor_name end)
        |> then(fn
          [] ->
            {:not_found, []}

          hosts ->
            {:ok, hosts}
        end)
    end
  end

  @spec get_hosts_by_actor_parent(String.t(), String.t()) :: {:ok, Member.t()} | {:not_found, []}
  def get_hosts_by_actor_parent(_system_name, actor_name) do
    case StateHandoff.get(actor_name) do
      nil ->
        {:not_found, []}

      hosts ->
        Enum.filter(hosts, fn ac -> ac.actor.id.parent == actor_name end)
        |> then(fn
          [] ->
            {:not_found, []}

          hosts ->
            {:ok, hosts}
        end)
    end
  end

  def node_cleanup(node) do
    Logger.info("Actor registry cleaning actors from node: #{inspect(node)}")

    StateHandoff.clean(node)
  end
end
