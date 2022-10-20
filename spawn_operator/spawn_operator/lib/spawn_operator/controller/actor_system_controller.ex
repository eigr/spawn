defmodule SpawnOperator.Controller.ActorSystemController do
  require Bonny.API.CRD

  use Bonny.ControllerV2,
    for_resource:
      Bonny.API.CRD.build_for_controller!(
        group: "spawn-eigr.io",
        scope: :Namespaced,
        versions: [SpawnOperator.Versions.Api.V1.ActorSystem]
      )

  use SpawnOperator.Handler.ActorSystemHandler

  rbac_rule({"v1", ["pods"], ["*"]})
  rbac_rule({"apps", ["deployments"], ["*"]})
  rbac_rule({"", ["secrets"], ["*"]})
  rbac_rule({"", ["services", "configmaps"], ["*"]})
end
