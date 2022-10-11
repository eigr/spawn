defmodule SpawnSdk.Interface do
  use Actors.Actor.Interface

  import SpawnSdk.System.SpawnSystem, only: [call: 3]

  @impl true
  def invoke_host(payload, state, default_methods) do
    call(payload, state, default_methods)
  end
end
