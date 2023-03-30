defmodule SpawnOperator.Handler.ActorSystemHandler do
  @moduledoc """
  `ActorSystemHandler` handles ActorSystem CRD events

      ---
      apiVersion: spawn.eigr.io/v1
      kind: ActorSystem
      metadata:
        name: spawn-system # Mandatory. Name of the state store
        namespace: default # Optional. Default namespace is "default"
      spec:
        cluster: # Optional
          kind: erlang # Optional. Default erlang. Possible values [erlang | quic]
          cookie: default-c21f969b5f03d33d43e04f8f136e7682 # Optional. Only used if kind is erlang
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
  alias SpawnOperator.K8s.System.Secret.ActorSystemSecret

  @behaviour Pluggable

  @impl Pluggable
  def init(_opts), do: nil

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:add, :modify] do
    %Bonny.Axn{resource: resource} = axn

    cluster_secret = build_system_secret(resource)
    cluster_service = build_system_service(resource)

    axn
    |> Bonny.Axn.register_descendant(cluster_secret)
    |> Bonny.Axn.register_descendant(cluster_service)
    |> Bonny.Axn.success_event()
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:delete, :reconcile] do
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
end
