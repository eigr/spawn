defmodule SpawnOperator.K8s.Activators.Simple.Service.Service do
  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(resource, _opts \\ []), do: %{}
end
