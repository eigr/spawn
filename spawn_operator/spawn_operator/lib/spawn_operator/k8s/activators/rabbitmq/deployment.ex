defmodule SpawnOperator.K8s.Activators.Rabbitmq.Deployment do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(_resource, _opts \\ []), do: %{}
end
