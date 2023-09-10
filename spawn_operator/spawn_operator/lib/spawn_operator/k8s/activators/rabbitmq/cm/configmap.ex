defmodule SpawnOperator.K8s.Activators.Rabbitmq.Cm.Configmap do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(
        %{
          system: system,
          namespace: ns,
          name: name,
          params: spec,
          labels: labels,
          annotations: annotations
        } = resource,
        _opts \\ []
      ) do
    %{}
  end
end
