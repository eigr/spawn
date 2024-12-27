defmodule Actors.Actor.Pool do
  @moduledoc """
  This module provides functions for creating actor host pools for pooled actors.
  """

  require Logger

  alias Actors.Registry.HostActor

  alias Spawn.Actors.{
    Actor,
    ActorId,
    ActorSettings
  }

  alias Spawn.Utils.Common

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
        %Actor{id: %ActorId{} = _id, settings: %ActorSettings{} = _settings} = actor,
        opts
      ) do
    opts = Keyword.merge(opts, hash: Common.actor_host_hash())

    [%HostActor{node: Node.self(), actor: actor, opts: opts}]
  end
end
