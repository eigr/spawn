defmodule SpawnOperator do
  @moduledoc """
  Documentation for `SpawnOperator`.
  """
  require Logger

  @actorsystem_label "spawn-eigr.io.actor-system"
  @actorsystem_default_name "spawn-system"

  def get_args(resource) do
    _metadata = K8s.Resource.metadata(resource)
    labels = K8s.Resource.labels(resource)
    annotations = K8s.Resource.annotations(resource)

    name = K8s.Resource.name(resource)
    ns = K8s.Resource.name(resource) || "default"

    system =
      if K8s.Resource.has_label?(resource, @actorsystem_label),
        do: K8s.Resource.label(resource, @actorsystem_label),
        else: @actorsystem_default_name

    spec = Map.get(resource, "spec")

    %{
      system: system,
      namespace: ns,
      name: name,
      params: spec,
      labels: labels,
      annotations: annotations
    }
  end
end
