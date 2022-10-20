defmodule SpawnOperator.Controller.ActorHostController do
  require Bonny.API.CRD

  use Bonny.ControllerV2,
    for_resource:
      Bonny.API.CRD.build_for_controller!(
        group: "spawn-eigr.io",
        scope: :Namespaced,
        versions: [SpawnOperator.Versions.Api.V1.ActorHost]
      )

  use SpawnOperator.Handler.ActorHostHandler

  rbac_rule({"", ["secrets"], ["*"]})
  rbac_rule({"v1", ["pods"], ["*"]})
  rbac_rule({"apps", ["deployments"], ["*"]})
  rbac_rule({"", ["services", "configmaps"], ["*"]})
  rbac_rule({"autoscaling", ["horizontalpodautoscalers"], ["*"]})
  rbac_rule({"extensions", ["ingresses", "ingressclasses"], ["*"]})
  rbac_rule({"networking.k8s.io", ["ingresses", "ingressclasses"], ["*"]})
end
