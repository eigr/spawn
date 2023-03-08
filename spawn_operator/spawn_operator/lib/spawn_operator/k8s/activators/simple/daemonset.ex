defmodule SpawnOperator.K8s.Activators.Simple.Daemonset do
  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(resource, _opts \\ []), do: %{}
end
