defmodule SpawnOperator.Handler.ActorHostHandler do
  @moduledoc """
  `ActorHostHandler` handles ActorHost CRD events

      ---
      apiVersion: spawn-eigr.io/v1
      kind: ActorHost
      metadata:
        name: my-node-app # Mandatory. Name of the Node containing Actor Host Functions
        system: my-actor-system # mandatory. Name of the ActorSystem declared in ActorSystem CRD
        namespace: default # Optional. Default namespace is "default"
      spec:
        autoscaler: # Optional
          min: 1
          max: 2
          averageCpuUtilizationPercentage: 80
          averageMemoryUtilizationValue: 250

        affinity: k8s_affinity_declaration_here # Optional

        replicas: 1 # Optional. If negative number than autoscaling is enable

        host: # Mandatory
          image: docker.io/eigr/spawn-springboot-examples:latest # Mandatory
          embedded: false # Optional. Default false. True only when the SDK supports a native connection to the Spawn mesh network
          ports:
          - containerPort: 80

        sidecar: # Optional. If embedded true then this section will be ignored
          image: docker.io/eigr/spawn-proxy:0.5.0

  """

  alias SpawnOperator.K8s.ConfigMap.SidecarCM
  alias SpawnOperator.K8s.{Deployment, HPA, Service}

  @behaviour Pluggable

  @impl Pluggable
  def init(_opts), do: nil

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:add, :modify] do
    %Bonny.Axn{resource: resource} = axn
    host_resource = build_host_deploy(resource)
    host_config_map = build_host_configmap(resource)
    host_hpa = build_host_hpa(resource)
    host_service = build_host_service(resource)

    axn
    |> Bonny.Axn.register_descendant(host_config_map)
    |> Bonny.Axn.register_descendant(host_resource)
    |> Bonny.Axn.register_descendant(host_service)
    |> IO.inspect(label: "Arhhhhhhhhhhhhhhhhhh")
    |> Bonny.Axn.register_descendant(host_hpa)
    |> Bonny.Axn.success_event()
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:delete, :reconcile] do
    Bonny.Axn.success_event(axn)
  end

  defp build_host_deploy(resource) do
    %{system: system, namespace: ns, name: name, params: params} =
      SpawnOperator.get_args(resource)

    Deployment.manifest(system, ns, name, params)
  end

  defp build_host_service(resource) do
    %{system: system, namespace: ns, name: name, params: params} =
      SpawnOperator.get_args(resource)

    Service.manifest(system, ns, name, params)
  end

  defp build_host_configmap(resource) do
    %{system: system, namespace: ns, name: name, params: params} =
      SpawnOperator.get_args(resource)

    SidecarCM.manifest(system, ns, name, params)
  end

  defp build_host_hpa(resource) do
    %{system: system, namespace: ns, name: name, params: params} =
      SpawnOperator.get_args(resource)

    HPA.manifest(system, ns, name, params)
  end
end
