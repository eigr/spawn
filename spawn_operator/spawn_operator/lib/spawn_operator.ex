defmodule SpawnOperator do
  @moduledoc """
  Documentation for `SpawnOperator`.
  """
  require Logger

  SpawnOperator.K8s.ConfigMap.SidecarCM

  alias SpawnOperator.K8s.{Deployment, ActorSystem}

  alias SpawnOperator.K8s.ConfigMap.{
    ActivatorCM,
    ActorSystemCM,
    SidecarCM
  }

  import Bonny.Config, only: [conn: 0]
  import Bonny.Resource, only: [add_owner_reference: 2]

  @doc """
  ---
  apiVersion: spawn.eigr.io/v1
  kind: ActorSystem
  metadata:
    name: spawn-system # Mandatory. Name of the state store
    namespace: default # Optional. Default namespace is "default"
  spec:
    mesh: # Optional
      kind: erlang # Optional. Default erlang. Possible values [erlang | quic]
      cookie: default-c21f969b5f03d33d43e04f8f136e7682 # Optional. Only used if kind is erlang
    statestore:
      type: Postgres
      databaseName: eigr-functions-db
      databaseHost: someHost
      databasePort: 5432
      statestoreCryptoKey: "3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE="
      credentialsSecretRef: postgres-connection-secret # The secret containing connection params
      pool: # Optional
        size: 10


  """
  def build_actor_system(resource) do
    system_configmap = build_system_configmap(resource)

    case apply_resource(resource, [system_configmap]) do
      :ok ->
        {:ok, "ActorSystem Created Suscessfully"}

      error ->
        {:error, "Failure to create ActorSystem. Cause #{inspect(error)}"}
    end
  end

  @doc """
  ---
  apiVersion: spawn-eigr.io/v1
  kind: ActorHost
  metadata:
    name: my-node-app # Mandatory. Name of the Node containing Actor Host Functions
    system: my-actor-system # mandatory. Name of the ActorSystem declared in ActorSystem CRD
    namespace: default # Optional. Default namespace is "default"
  spec:
    affinity: k8s_affinity_declaration_here # Optional

    replicas: 1 # Optional. If negative number than autoscaling is enable

    host: # Mandatory
      image: docker.io/eigr/spawn-springboot-examples:latest # Mandatory
      embedded: false # Optional. Default false. True only when the SDK supports a native connection to the Spawn mesh network
      ports:
      - containerPort: 80

    sidecar: # Optional. If embedded true then this section will be ignored
      image: docker.io/eigr/spawn-proxy:0.1.0

  """
  def build_actor_host(resource) do
    host_resource = build_host_deploy(resource)
    host_config_map = build_host_configmap(resource)

    case apply_resource(resource, [host_config_map, host_resource]) do
      :ok ->
        {:ok, "Actor Host Function created suscessfully"}

      error ->
        {:error, "Failure to create Actor Host Function. Cause #{inspect(error)}"}
    end
  end

  defp build_host_deploy(resource) do
    %{system: system, namespace: ns, name: name, params: params} = get_args(resource)
    Deployment.manifest(system, ns, name, params)
  end

  defp build_host_configmap(resource) do
    %{system: system, namespace: ns, name: name, params: params} = get_args(resource)
    SidecarCM.manifest(system, ns, name, params)
  end

  defp build_system_configmap(resource) do
    %{system: system, namespace: ns, name: name, params: params} = get_args(resource)
    ActorSystem.manifest(system, ns, name, params)
  end

  defp get_args(resource) do
    metadata = Map.fetch!(resource, "metadata")

    ns = Map.get(metadata, "namespace", "default")
    name = Map.fetch!(metadata, "name")
    system = Map.get(metadata, "system", "spawn-system")
    params = Map.get(resource, "spec")

    %{system: system, namespace: ns, name: name, params: params}
  end

  defp apply_resource(crd, resources) when is_list(resources) do
    resources
    |> Enum.each(fn resource ->
      kind = Map.get(resource, "kind")
      Logger.debug("Applying resource #{inspect(kind)}")
      apply_resource(crd, resource)
    end)
  end

  defp apply_resource(crd, resource) when is_map(resource) do
    result =
      resource
      |> add_owner_reference(crd)
      |> IO.inspect()
      |> K8s.Client.create()
      |> then(&K8s.Client.run(conn(), &1))
      |> IO.inspect(label: "Result ------------")

    # IO.inspect(result, label: "Result ------------")
    result
  end

  def track_event(type, resource) do
    kind = Map.get(resource, "kind")
    Logger.info("#{type}: #{inspect(kind)}")
  end
end
