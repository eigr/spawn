defmodule SpawnOperator.Versions.Api.V1.ActorSystem do
  use Bonny.API.Version

  @impl true
  def manifest(), do: defaults()
end
