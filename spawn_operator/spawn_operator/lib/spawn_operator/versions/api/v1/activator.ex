defmodule SpawnOperator.Versions.Api.V1.Activator do
  use Bonny.API.Version

  @impl true
  def manifest(), do: defaults()
end
