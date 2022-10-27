defmodule SpawnOperator.Versions.Api.V1.Activator do
  use Bonny.API.Version

  @impl true
  def manifest() do
    defaults()
    |> struct!(
      name: "v1",
      storage: true
    )
    # |> add_observed_generation_status()
  end
end
