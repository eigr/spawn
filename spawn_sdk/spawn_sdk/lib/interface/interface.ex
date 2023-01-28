defmodule SpawnSdk.Interface do
  @moduledoc """
  Implements the communication protocol between Elixir SDK and Sidecar.
  """
  use Actors.Actor.Interface

  import SpawnSdk.System.SpawnSystem, only: [call: 3]

  @impl true
  def invoke_host(payload, state, default_methods) do
    call(payload, state, default_methods)
  end
end
