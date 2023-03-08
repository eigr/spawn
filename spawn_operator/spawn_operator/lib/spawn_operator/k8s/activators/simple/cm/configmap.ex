defmodule SpawnOperator.K8s.Activators.Simple.Cm.Configmap do
  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(resource, _opts \\ []), do: %{}
end
