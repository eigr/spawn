defmodule SpawnOperator.Controller.ActorSystemController do
  require Bonny.API.CRD

  use Bonny.ControllerV2

  step SpawnOperator.Handler.ActorSystemHandler

  def rbac_rules() do
    [
      to_rbac_rule({"v1", ["pods"], ["*"]}),
      to_rbac_rule({"apps", ["deployments"], ["*"]}),
      to_rbac_rule({"", ["secrets"], ["*"]}),
      to_rbac_rule({"", ["services", "configmaps"], ["*"]}),
    ]
  end
end
