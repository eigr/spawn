defmodule SpawnOperator.Handler.ActorSystemHandler do
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
  alias SpawnOperator.K8s.System.HeadlessService
  alias SpawnOperator.K8s.System.Namespace
  alias SpawnOperator.K8s.System.Role
  alias SpawnOperator.K8s.System.RoleBinding
  alias SpawnOperator.K8s.System.Secret.ActorSystemSecret
  alias SpawnOperator.K8s.System.ServiceAccount
  alias SpawnOperator.K8s.System.EpmdDS
  alias SpawnOperator.K8s.System.EpmdPolicy

  @behaviour Pluggable

  @impl Pluggable
  def init(_opts), do: nil

  @impl Pluggable
  def call(%Bonny.Axn{action: action, resource: resource} = axn, nil)
      when action in [:add, :modify] do
    :persistent_term.put(:resource_key, resource)

    descendants = [
      {:namespace, build_namespace(resource)},
      {:cluster_secret, build_system_secret(resource)},
      {:cluster_service, build_system_service(resource)},
      {:service_account, build_service_account(resource)},
      {:roles, build_role(resource)},
      {:role_binding, build_role_binding(resource)},
      {:epmd_daemonset, build_epmd_daemonset(resource)},
      {:epmd_network_policy, build_epmd_network_policy(resource)}
    ]

    axn =
      Enum.reduce(descendants, axn, fn {type, descendant}, acc ->
        if type == :namespace do
          acc
          |> Bonny.Axn.register_descendant(descendant, group: -1, omit_owner_ref: true)
          |> Bonny.Axn.set_condition(to_string(type), true, "#{type} registered successfully")
        else
          acc
          |> Bonny.Axn.register_descendant(descendant)
          |> Bonny.Axn.set_condition(to_string(type), true, "#{type} registered successfully")
        end
      end)

    Bonny.Axn.success_event(axn)
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: :delete} = axn, nil) do
    Bonny.Axn.success_event(axn)
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: :reconcile, resource: resource} = axn, nil) do
    # previous resource
    persisted_resource = :persistent_term.get(:resource_key, %{})

    if Map.equal?(resource, persisted_resource) do
      Bonny.Axn.success_event(axn)
    else
      handle_reconcile(axn, resource)
    end
  end

  defp handle_reconcile(axn, resource) do
    descendants = [
      {:cluster_secret, build_system_secret(resource)},
      {:cluster_service, build_system_service(resource)},
      {:service_account, build_service_account(resource)},
      {:roles, build_role(resource)},
      {:role_binding, build_role_binding(resource)}
    ]

    axn =
      Enum.reduce(descendants, axn, fn {type, descendant}, acc ->
        acc
        |> Bonny.Axn.register_descendant(descendant)
        |> Bonny.Axn.set_condition(to_string(type), true, "#{type} reconciled")
      end)

    Bonny.Axn.success_event(axn)
  end

  defp build_namespace(resource) do
    SpawnOperator.get_args(resource)
    |> Namespace.manifest()
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

  defp build_epmd_daemonset(resource) do
    SpawnOperator.get_args(resource)
    |> RoleBinding.manifest()
  end

  defp build_epmd_network_policy(resource) do
    SpawnOperator.get_args(resource)
    |> RoleBinding.manifest()
  end
end
