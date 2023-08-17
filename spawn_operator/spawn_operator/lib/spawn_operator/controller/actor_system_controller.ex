defmodule SpawnOperator.Controller.ActorSystemController do
  require Bonny.API.CRD

  use Bonny.ControllerV2

  step(Bonny.Pluggable.SkipObservedGenerations)
  step(SpawnOperator.Handler.ActorSystemHandler)

  def rbac_rules() do
    [
      to_rbac_rule({"rbac.authorization.k8s.io", "role", "*"}),
      to_rbac_rule({"", "serviceaccount", "*"}),
      to_rbac_rule({"", "pods", "*"}),
      to_rbac_rule({"", "node", ["get", "list"]}),
      to_rbac_rule({"apps", "deployments", "*"}),
      to_rbac_rule({"", "secrets", "*"}),
      to_rbac_rule({"", ["services", "configmaps"], "*"}),
      to_rbac_rule({"cert-manager.io", "certificate", "*"})
    ]
  end
end
