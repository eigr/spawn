defmodule SpawnOperator.Controller.ActivatorController do
  @moduledoc """
  `ActivatorHandler` handles Activator CRD events
  """
  use Bonny.ControllerV2
  require Bonny.API.CRD

  step(Bonny.Pluggable.SkipObservedGenerations)
  step :handle_event

  @impl true
  def rbac_rules() do
    [
      to_rbac_rule({"", ["secrets"], ["*"]}),
      to_rbac_rule({"batch", ["cronjob", "cronjobs", "job", "jobs"], ["*"]}),
      to_rbac_rule({"", ["pods"], ["*"]}),
      to_rbac_rule({"apps", ["deployments", "daemonsets"], ["*"]}),
      to_rbac_rule({"", ["services", "configmaps"], ["*"]}),
      to_rbac_rule({"autoscaling", ["horizontalpodautoscalers"], ["*"]}),
      to_rbac_rule({"extensions", ["ingresses", "ingressclasses"], ["*"]}),
      to_rbac_rule({"networking.k8s.io", ["ingresses", "ingressclasses"], ["*"]})
    ]
  end

  @impl Pluggable
  @spec handle_event(Bonny.Axn.t(), Keyword.t()) :: Bonny.Axn.t()
  def handle_event(%Bonny.Axn{action: action, resource: resource} = axn, nil)
    do:
      SpawnOperator.get_args(resource)
      |> Activator.apply(axn, action)
end
