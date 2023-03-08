defmodule SpawnOperator.K8s.Activators.Simple.Deployment do
  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(resource, _opts \\ []), do: %{}
end
