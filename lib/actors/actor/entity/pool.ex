defmodule Actors.Actor.Pool do
  @moduledoc """
  This module provides functions for creating actor host pools for pooled actors.
  """

  require Logger

  alias Actors.Registry.{ActorRegistry, HostActor}

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorSettings
  }

  @http_host_interface Actors.Actor.Interface.Http

  @doc """
  Creates an actor host pool for a given pooled actor.

  ## Parameters
  - `actor`: The actor for which the host pool should be created.
  - `opts`: Additional options for the host pool.

  ## Returns
  Returns a list of `HostActor` structs representing the hosts in the pool.
  """
  @spec create_actor_host_pool(Actor.t(), keyword()) :: list(HostActor.t())
  def create_actor_host_pool(
        %Actor{
          id: %ActorId{} = id,
          settings: %ActorSettings{kind: :POOLED} = _settings
        } = actor,
        opts
      ) do
    case ActorRegistry.get_hosts_by_actor(id) do
      {:ok, actor_hosts} ->
        build_pool(:distributed, actor, actor_hosts, opts)

      _ ->
        build_pool(:local, actor, nil, opts)
    end
  end

  def create_actor_host_pool(
        %Actor{settings: %ActorSettings{kind: _kind} = _settings} = actor,
        opts
      ) do
    [%HostActor{node: Node.self(), actor: actor, opts: opts}]
  end

  defp build_pool(
         :local,
         %Actor{
           id: %ActorId{system: system, parent: _parent, name: name} = _id,
           settings:
             %ActorSettings{kind: :POOLED, min_pool_size: min, max_pool_size: max} = _settings
         } = actor,
         _hosts,
         opts
       ) do
    {_current_value, new_opts} =
      Keyword.get_and_update(opts, :interface, fn current_value ->
        case current_value do
          nil ->
            {@http_host_interface, @http_host_interface}

          _ ->
            {current_value, current_value}
        end
      end)

    max_pool = if max < min, do: get_defaul_max_pool(min), else: max

    Enum.into(
      min..max_pool,
      [],
      fn index ->
        name_alias = build_name_alias(name, index)

        pooled_actor = %Actor{
          actor
          | id: %ActorId{system: system, parent: name_alias, name: name}
        }

        Logger.debug("Registering metadata for the Pooled Actor #{name} with Alias #{name_alias}")
        %HostActor{node: Node.self(), actor: pooled_actor, opts: new_opts}
      end
    )
  end

  defp build_pool(
         :distributed,
         %Actor{
           id: %ActorId{system: system, parent: _parent, name: name} = _id,
           settings:
             %ActorSettings{kind: :POOLED, min_pool_size: min, max_pool_size: max} = _settings
         } = actor,
         hosts,
         opts
       ) do
    {_current_value, new_opts} =
      Keyword.get_and_update(opts, :interface, fn current_value ->
        case current_value do
          nil ->
            {@http_host_interface, @http_host_interface}

          _ ->
            {current_value, current_value}
        end
      end)

    max_pool = if max < min, do: get_defaul_max_pool(min), else: max

    Enum.into(
      min..max_pool,
      [],
      fn index ->
        host = Enum.random(hosts)
        name_alias = build_name_alias(name, index)

        pooled_actor = %Actor{
          actor
          | id: %ActorId{system: system, parent: name_alias, name: name}
        }

        Logger.debug("Registering metadata for the Pooled Actor #{name} with Alias #{name_alias}")
        %HostActor{node: host.node, actor: pooled_actor, opts: new_opts}
      end
    )
  end

  defp build_name_alias(name, index), do: "#{name}-#{index}"

  defp get_defaul_max_pool(min_pool) do
    length(Node.list() ++ [Node.self()]) * (System.schedulers_online() + min_pool)
  end
end
