defmodule SpawnOperator.K8s.Activators.Api.Deployment do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(_resource, _opts \\ []), do: %{}
end
