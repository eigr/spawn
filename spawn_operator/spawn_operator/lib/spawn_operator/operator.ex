defmodule SpawnOperator.Operator do
  @moduledoc """
  This operator is responsible for managing the lifecycle of the Spawn Eigr resources.
  """
  use Bonny.Operator, default_watch_namespace: :all

  step(Bonny.Pluggable.Logger)
  step(:delegate_to_controller)
  step(Bonny.Pluggable.ApplyStatus)
  step(Bonny.Pluggable.ApplyDescendants)

  def crds() do
    [
      Bonny.API.CRD.new!(
        names:
          Bonny.API.CRD.kind_to_names("Activator", ["act", "acts", "activator", "activators"]),
        group: "spawn-eigr.io",
        scope: :Namespaced,
        versions: [SpawnOperator.Versions.Api.V1.Activator]
      ),
      Bonny.API.CRD.new!(
        names:
          Bonny.API.CRD.kind_to_names("ActorHost", [
            "ac",
            "ah",
            "actor",
            "actors",
            "actorhost",
            "actorhosts",
            "hosts",
          ]),
        group: "spawn-eigr.io",
        scope: :Namespaced,
        versions: [SpawnOperator.Versions.Api.V1.ActorHost]
      ),
      Bonny.API.CRD.new!(
        names:
          Bonny.API.CRD.kind_to_names("ActorSystem", [
            "as",
            "actorsys",
            "actorsystem",
            "actorsystems",
            "system"
          ]),
        group: "spawn-eigr.io",
        scope: :Cluster,
        versions: [SpawnOperator.Versions.Api.V1.ActorSystem]
      )
    ]
  end

  @impl true
  def controllers(watch_namespace, _opts) do
    [
      %{
        query: K8s.Client.watch("spawn-eigr.io/v1", "Activator", namespace: watch_namespace),
        controller: SpawnOperator.Controller.ActivatorController
      },
      %{
        query: K8s.Client.watch("spawn-eigr.io/v1", "ActorHost", namespace: watch_namespace),
        controller: SpawnOperator.Controller.ActorHostController
      },
      %{
        query: K8s.Client.watch("spawn-eigr.io/v1", "ActorSystem"),
        controller: SpawnOperator.Controller.ActorSystemController
      }
    ]
  end
end
