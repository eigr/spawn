defmodule SpawnOperator.K8s.Activators.Scheduler.DaemonSetService do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(resource, _opts \\ []), do: %{}
end
