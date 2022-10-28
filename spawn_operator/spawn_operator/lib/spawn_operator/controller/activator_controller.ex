defmodule SpawnOperator.Controller.ActivatorController do
  require Bonny.API.CRD

  use Bonny.ControllerV2

  step(Bonny.Pluggable.SkipObservedGenerations)
  step(SpawnOperator.Handler.ActivatorHandler)

  @impl true
  def rbac_rules() do
    [
      to_rbac_rule({"", ["secrets"], ["*"]}),
      to_rbac_rule({"v1", ["pods"], ["*"]}),
      to_rbac_rule({"apps", ["deployments", "daemonsets"], ["*"]}),
      to_rbac_rule({"", ["services", "configmaps"], ["*"]}),
      to_rbac_rule({"autoscaling", ["horizontalpodautoscalers"], ["*"]}),
      to_rbac_rule({"extensions", ["ingresses", "ingressclasses"], ["*"]}),
      to_rbac_rule({"networking.k8s.io", ["ingresses", "ingressclasses"], ["*"]})
    ]
  end
end
