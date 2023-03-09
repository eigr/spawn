defmodule SpawnOperator.K8s.Activators.Scheduler.CronJob do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(resource, _opts \\ []), do: %{}
end
