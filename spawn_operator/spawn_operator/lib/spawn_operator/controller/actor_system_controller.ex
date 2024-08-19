defmodule SpawnOperator.Controller.ActorSystemController do
  @moduledoc """
  `ActorSystemHandler` handles ActorSystem CRD events

      ---
      apiVersion: spawn-eigr.io/v1
      kind: ActorSystem
      metadata:
        name: spawn-system # Mandatory. Name of the state store
        namespace: default # Optional. Default namespace is "default"
      spec:
        cluster: # Optional
          kind: erlang # Optional. Default erlang. Possible values [erlang | quic]
          cookie: default-c21f969b5f03d33d43e04f8f136e7682 # Optional. Only used if kind is erlang
          systemToSystem:
            enabled: true
            natsClusterSecretRef: nats-config-secret
          tls:
            secretName: spawn-system-tls-secret
            certManager:
              enabled: true # Default false
              issuerName: spawn-system-issuer # You must create an Issuer previously according to certmanager documentation

        statestore:
          type: Postgres
          credentialsSecretRef: postgres-connection-secret # The secret containing connection params
          pool: # Optional
            size: 10

  """
  use Bonny.ControllerV2
  require Bonny.API.CRD

  alias SpawnOperator.K8s.System.HeadlessService
  alias SpawnOperator.K8s.System.Secret.ActorSystemSecret
  alias SpawnOperator.K8s.System.Role
  alias SpawnOperator.K8s.System.RoleBinding
  alias SpawnOperator.K8s.System.ServiceAccount

  step(Bonny.Pluggable.SkipObservedGenerations)
  step :handle_event

  @impl true
  def rbac_rules() do
    [
      to_rbac_rule({"rbac.authorization.k8s.io", ["role", "roles", "rolebindings"], "*"}),
      to_rbac_rule({"", ["serviceaccount", "serviceaccounts"], "*"}),
      to_rbac_rule({"", "pods", "*"}),
      to_rbac_rule({"", ["node", "nodes"], ["get", "list"]}),
      to_rbac_rule({"apps", "deployments", "*"}),
      to_rbac_rule({"", "secrets", "*"}),
      to_rbac_rule({"", ["services", "configmaps"], "*"}),
      to_rbac_rule({"cert-manager.io", "certificate", "*"})
    ]
  end

  @spec handle_event(Bonny.Axn.t(), Keyword.t()) :: Bonny.Axn.t()
  def handle_event(%Bonny.Axn{action: action, resource: resource} = axn, nil)
      when action in [:add, :modify] do
    %Bonny.Axn{resource: resource} = axn

    cluster_secret = build_system_secret(resource)
    cluster_service = build_system_service(resource)
    service_account = build_service_account(resource)
    roles = build_role(resource)
    role_binding = build_role_binding(resource)

    axn
    |> Bonny.Axn.register_descendant(cluster_secret)
    |> Bonny.Axn.register_descendant(cluster_service)
    |> Bonny.Axn.register_descendant(service_account)
    |> Bonny.Axn.register_descendant(roles)
    |> Bonny.Axn.register_descendant(role_binding)
    |> Bonny.Axn.success_event()
  end

  @spec handle_event(Bonny.Axn.t(), Keyword.t()) :: Bonny.Axn.t()
  def handle_event(%Bonny.Axn{action: action} = axn, nil) when action in [:delete, :reconcile] do
    Bonny.Axn.success_event(axn)
  end

  defp build_system_secret(resource) do
    SpawnOperator.get_args(resource)
    |> ActorSystemSecret.manifest()
  end

  defp build_system_service(resource) do
    SpawnOperator.get_args(resource)
    |> HeadlessService.manifest()
  end

  defp build_service_account(resource) do
    SpawnOperator.get_args(resource)
    |> ServiceAccount.manifest()
  end

  defp build_role(resource) do
    SpawnOperator.get_args(resource)
    |> Role.manifest()
  end

  defp build_role_binding(resource) do
    SpawnOperator.get_args(resource)
    |> RoleBinding.manifest()
  end
end
