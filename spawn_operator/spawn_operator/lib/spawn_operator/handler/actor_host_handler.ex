defmodule SpawnOperator.Handler.ActorHostHandler do
  @moduledoc """
  `ActorHostHandler` handles ActorHost CRD events

      ---
      apiVersion: spawn-eigr.io/v1
      kind: ActorHost
      metadata:
        name: my-node-app # Mandatory. Name of the Node containing Actor Host Functions
        namespace: default # Optional. Default namespace is "default"
        labels:
          # Mandatory. Name of the ActorSystem declared in ActorSystem CRD
          spawn-eigr.io.actor-system: my-actor-system

          # Optional
          spawn-eigr.io.cluser.polingInterval: 3000

          # Optional. Default "sidecar". Possible values are "sidecar" | "daemon"
          spawn-eigr.io.sidecar.deploymentMode: "sidecar"

          # Optional
          spawn-eigr.io.sidecar.containerImage: "docker.io/eigr/spawn-proxy"

          # Optional
          spawn-eigr.io.sidecar.containerVersion: "0.5.5"

          # Optional. Default 9001
          spawn-eigr.io.sidecar.httpPort: 9001

          # Optional. Default false
          spawn-eigr.io.sidecar.udsEnable: false

          # Optional. Default "/var/run/spawn.sock"
          spawn-eigr.io.sidecar.udsAddress: "/var/run/sidecar.sock"

          # Optional. Default false
          spawn-eigr.io.sidecar.disableMetrics: false

          # Optional. Default true
          spawn-eigr.io.sidecar.consoleDisableMetrics: true

          # Optional
          spawn-eigr.io.sidecar.userFunctionHost: "0.0.0.0"

          # Optional
          spawn-eigr.io.sidecar.userFunctionPort: 8090

          # Optional. Default "native".
          # Using Phoenix PubSub Adapter.
          # Possible values: "native" | "nats"
          spawn-eigr.io.sidecar.pubsub.adapter: "native"

          # Optional. Default "nats://127.0.0.1:4222"
          spawn-eigr.io.sidecar.pubsub.nats.hosts: "nats://127.0.0.1:4222"

          # Optional. Default false
          spawn-eigr.io.sidecar.pubsub.nats.tls: "false"

          # Optional. Default false
          spawn-eigr.io.sidecar.pubsub.nats.auth: false

          # Optioal. Default "simple"
          spawn-eigr.io.sidecar.pubsub.nats.authType: "simple"

          # Optional. Default "admin"
          spawn-eigr.io.sidecar.pubsub.nats.authUser: "admin"

          # Optional. Default "admin"
          spawn-eigr.io.sidecar.pubsub.nats.authPass: "admin"

          # Optional. Default ""
          spawn-eigr.io.sidecar.pubsub.nats.authJwt: ""
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

  """

  alias SpawnOperator.K8s.Proxy.{CM.Configmap, Deployment, HPA, Service}

  @behaviour Pluggable

  @impl Pluggable
  def init(_opts), do: nil

  @impl Pluggable
  def call(%Bonny.Axn{action: action, resource: resource} = axn, nil)
      when action in [:add, :modify] do
    host_config_map = build_host_configmap(resource)
    host_resource = build_host_deploy(resource)
    host_hpa = build_host_hpa(resource)
    host_service = build_host_service(resource)

    axn
    |> Bonny.Axn.register_descendant(host_hpa)
    |> Bonny.Axn.register_descendant(host_service)
    |> Bonny.Axn.register_descendant(host_config_map)
    |> Bonny.Axn.register_descendant(host_resource)
    # |> Bonny.Axn.update_status(fn status ->
    #  put_in(status, [Access.key(:some, %{}), :field], "foo")
    # end)
    |> Bonny.Axn.success_event()
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:reconcile] do
    # TODO: Reconcile hpa for rebalancing Nodes
    # TODO: Recreate resources if not exists
    Bonny.Axn.success_event(axn)
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:delete] do
    Bonny.Axn.success_event(axn)
  end

  defp build_host_deploy(resource) do
    SpawnOperator.get_args(resource)
    |> Deployment.manifest()
  end

  defp build_host_service(resource) do
    SpawnOperator.get_args(resource)
    |> Service.manifest()
  end

  defp build_host_configmap(resource) do
    SpawnOperator.get_args(resource)
    |> Configmap.manifest()
  end

  defp build_host_hpa(resource) do
    SpawnOperator.get_args(resource)
    |> HPA.manifest()
  end
end
