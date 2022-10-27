defmodule SpawnOperator do
  @moduledoc """
  Documentation for `SpawnOperator`.
  """
  require Logger

  def get_args(resource) do
    metadata = Map.fetch!(resource, "metadata")

    ns = Map.get(metadata, "namespace", "default")
    name = Map.fetch!(metadata, "name")
    system = Map.get(metadata, "system", "spawn-system")
    params = Map.get(resource, "spec")

    %{system: system, namespace: ns, name: name, params: params}
  end
end
