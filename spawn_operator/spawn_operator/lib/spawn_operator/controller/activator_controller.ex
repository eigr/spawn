defmodule SpawnOperator.Controller.ActivatorController do
  require Bonny.API.CRD

  use Bonny.ControllerV2,
    for_resource:
      Bonny.API.CRD.build_for_controller!(
        group: "spawn-eigr.io",
        scope: :Namespaced,
        versions: [SpawnOperator.Versions.Api.V1.Activator]
      )

  use SpawnOperator.Handler.ActivatorHandler

  rbac_rule({"", ["secrets"], ["*"]})
  rbac_rule({"v1", ["pods"], ["*"]})
  rbac_rule({"apps", ["deployments", "daemonsets"], ["*"]})
  rbac_rule({"", ["services", "configmaps"], ["*"]})
  rbac_rule({"autoscaling", ["horizontalpodautoscalers"], ["*"]})
  rbac_rule({"extensions", ["ingresses", "ingressclasses"], ["*"]})
  rbac_rule({"networking.k8s.io", ["ingresses", "ingressclasses"], ["*"]})
end
