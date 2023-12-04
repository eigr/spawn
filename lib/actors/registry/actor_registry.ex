defmodule Actors.Registry.ActorRegistry do
  @moduledoc """
  The `ActorRegistry` module provides a registry for actor entities.

  It allows for registering and looking up actors and also provides
  methods for adding and removing invocation requests for actors.
  """

  use Retry

  require Logger

  alias Actors.Registry.{HostActor, LoadBalancer}
  alias Eigr.Functions.Protocol.Actors.{Actor, ActorId}
  alias Spawn.Cluster.StateHandoff.Manager, as: StateHandoff

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
    Enum.each(hosts, fn host ->
      retry with: exponential_backoff() |> randomize |> expiry(10_000),
            atoms: [:error, :too_many_requests],
            rescue_only: [ErlangError] do
        try do
          StateHandoff.set(host.actor.id, host)
        rescue
          e ->
            Logger.error(
              "Error to register actor #{inspect(host.actor.id)} for host #{inspect(host)}: #{inspect(e)}"
            )

            reraise e, __STACKTRACE__
        end
      after
        result -> result
      else
        error -> error
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
    # TODO: Fix this
    # StateHandoff.get_all_invocations()
  end

  @doc """
  Removes a invocation request in CRDT Database
  Usually used for invocation schedulings
  """
  def remove_invocation_request(_actor, _request) do
    # TODO: Fix this
    # actor
    # |> StateHandoff.get()
    # |> Kernel.||([])
    # |> Enum.map(fn host ->
    #   invocations = host.opts[:invocations] || []
    #   invocation = Enum.find(invocations, &(&1 == request))
    #   invocations = invocations -- [invocation]

    #   opts = Keyword.put(host.opts, :invocations, invocations)
    #   %{host | opts: opts}
    # end)
    # |> then(fn
    #   [] ->
    #     :nothing

    #   updated_hosts ->
    #     StateHandoff.set(actor, updated_hosts)
    # end)
  end

  @doc """
  Registers a invocation request in CRDT Database
  Usually used for invocation schedulings
  """
  def register_invocation_request(_actor, _request) do
    # TODO: Fix this
    # actor
    # |> StateHandoff.get()
    # |> Kernel.||([])
    # |> Enum.map(fn host ->
    #   invocations = (host.opts[:invocations] || []) ++ [request]

    #   opts = Keyword.put(host.opts, :invocations, invocations)
    #   %{host | opts: opts}
    # end)
    # |> then(fn
    #   [] ->
    #     :nothing

    #   updated_hosts ->
    #     StateHandoff.set(actor, updated_hosts)
    # end)
  end

  @doc """
  Fetch current entities of the service.
  Returns `HostActor` with Host and specific actor.
  """
  @doc since: "0.1.0"
  @spec lookup(ActorId.t(), Keyword.t()) :: {:ok, HostActor.t()} | {:not_found, []}
  def lookup(id, opts \\ []) do
    case StateHandoff.get(id) do
      nil ->
        {:not_found, []}

      state_hosts ->
        parent_name = Keyword.get(opts, :parent, nil)
        filter_by_parent? = Keyword.get(opts, :filter_by_parent, false)

        case filter(state_hosts, filter_by_parent?, id) do
          [] -> {:not_found, []}
          hosts -> choose_hosts(hosts, filter_by_parent?, id, parent_name)
        end
    end
  end

  @doc """
  Retrieves a list of hosts associated with a given actor.
  Parameters

  actor_id (%ActorId{}): The ID of the actor.
  opts (Keyword, optional): Options for the function.
      :parent (boolean): If true, filter hosts by parent; otherwise, filter by name.

  Returns

  {:ok, hosts}: A tuple with :ok and a list of hosts.
  {:not_found, []}: If no hosts are found.

  Examples

  ```elixir
  actor_id = %ActorId{parent: "parent", name: "name"}
  opts = [parent: true]
  {:ok, hosts} = Actors.Registry.ActorRegistry.get_hosts_by_actor(actor_id, opts)

  ```
  """
  @spec get_hosts_by_actor(ActorId.t(), Keyword.t()) :: {:ok, Member.t()} | {:not_found, []}
  def get_hosts_by_actor(
        %ActorId{parent: parent, name: name} = actor_id,
        opts \\ []
      ) do
    parent? = Keyword.get(opts, :parent, false)

    {id, actor_name} =
      if parent? do
        {%ActorId{actor_id | name: parent}, parent}
      else
        {actor_id, name}
      end

    case StateHandoff.get(id) do
      nil ->
        {:not_found, []}

      hosts ->
        Enum.filter(hosts, &(&1.actor.id.name == actor_name))
        |> then(fn
          [] -> {:not_found, []}
          hosts -> {:ok, hosts}
        end)
    end
  end

  # This version combines the conditions into a single expression for brevity while retaining the core logic.
  # It uses the && and || operators to express the conditions more succinctly.
  # It's important to note that this optimization sacrifices some readability for brevity.
  # As always, when prioritizing performance,
  defp filter(hosts, filter_by_parent?, %ActorId{name: actor_name, parent: parent_name}) do
    Enum.filter(hosts, fn ac ->
      (filter_by_parent? && ac.actor.id.parent == parent_name) ||
        (not filter_by_parent? && ac.actor.id.name == actor_name)
    end)
  end

  defp choose_hosts(hosts, filter_by_parent?, %ActorId{name: _actor_name} = _id, parent_name) do
    if filter_by_parent? do
      %HostActor{node: _node, actor: actor, opts: opts} = host = Enum.random(hosts)
      new_actor = %Actor{actor | id: %ActorId{actor.id | name: parent_name}}
      {:ok, %HostActor{host | actor: new_actor, opts: opts}}
    else
      case LoadBalancer.next_host(hosts) do
        {:ok, node_host, _updated_hosts} ->
          {:ok, node_host}

        _ ->
          {:not_found, []}
      end
    end
  end
end
