defmodule SpawnOperator.Handler.ActorHostHandler do
  @moduledoc """
  `ActorHostHandler` handles ActorHost CRD events
  """

  import SpawnOperator,
    only: [
      build_actor_host: 1,
      track_event: 2
    ]

  @behaviour Pluggable

  @impl Pluggable
  def init(_opts), do: nil

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in[:add, :modify] do
    track_event(action, axn.resource)
    build_actor_host(axn.resource)
    Bonny.Axn.success_event(axn)
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in[:delete, :reconcile] do
    track_event(action, axn.resource)
    Bonny.Axn.success_event(axn)
  end
end
