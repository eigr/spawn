defmodule SpawnOperator.K8s.ConfigMap.ActivatorCM do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(_resource, _opts \\ []), do: %{}
end
