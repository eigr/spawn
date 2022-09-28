defmodule SpawnSdk.Interface do
  use Actors.Actor.Interface
  require Logger

  alias Actors.Actor.Entity.EntityState

  alias SpawnSdk.System.SpawnSystem

  @impl true
  def invoke_host(payload, state, default_methods) do
    SpawnSystem.call(payload, state, default_methods)
  end
end
