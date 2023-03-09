defmodule SpawnOperator.K8s.Activators.Scheduler.Cm.Configmap do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(resource, _opts \\ []), do: %{}
end
