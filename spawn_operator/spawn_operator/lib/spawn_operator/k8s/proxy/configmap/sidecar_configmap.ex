defmodule SpawnOperator.K8s.Proxy.CM.Configmap do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @doc """
  ConfigMap is generated using following CRD labels:

  annotations:
    # Mandatory. Name of the ActorSystem declared in ActorSystem CRD
    spawn-eigr.io/actor-system: test-1

    # Optional. User Function Host Address
    spawn-eigr.io/app-host: "0.0.0.0"

    # Optional. User Function Host Port
    spawn-eigr.io/app-port: "8090"

     # Optional
    spawn-eigr.io/cluster-poling-interval: "3000"

    # Optional. Default "sidecar". Possible values are "sidecar" | "daemon"
    spawn-eigr.io/sidecar-mode: "sidecar"

    # Optional
    spawn-eigr.io/sidecar-image-tag: "docker.io/eigr/spawn-proxy:1.0.0-rc.26"

    # Optional. Default 9001
    spawn-eigr.io/sidecar-http-port: "9001"

    # Optional. Default "0.0.0.0"
    spawn-eigr.io/sidecar-address: "127.0.0.1"

    # Optional. Default false
    spawn-eigr.io/sidecar-uds-enabled: "false"

    # Optional. Default "/var/run/spawn.sock"
    spawn-eigr.io/sidecar-uds-socket-path: "/var/run/sidecar.sock"

    # Optional. Default "9090"
    spawn-eigr.io/sidecar-metrics-port: "9090"

    # Optional. Default false
    spawn-eigr.io/sidecar-metrics-disabled: "false"

    # Optional. Default true
    spawn-eigr.io/sidecar-metrics-log-console: "true"

    # Optional. Default "native".
    # Using Phoenix PubSub Adapter.
    # Possible values: "native" | "nats"
    spawn-eigr.io/sidecar-pubsub-adapter: "native"

    # Optional. Default "nats://127.0.0.1:4222"
    spawn-eigr.io/sidecar-pubsub-nats-hosts: "nats://127.0.0.1:4222"

    # Optional. Default false
    spawn-eigr.io/sidecar-pubsub-nats-tls: "false"

    # Optional. Default false
    spawn-eigr.io/sidecar-pubsub-nats-auth: "false"

    # Optioal. Default "simple"
    spawn-eigr.io/sidecar-pubsub-nats-auth-type: "simple"

    # Optional. Default "admin".
    spawn-eigr.io/sidecar-pubsub-nats-auth-user: "admin"

    # Optional. Default "admin"
    spawn-eigr.io/sidecar-pubsub-nats-auth-pass: "admin"

    # Optional. Default ""
    spawn-eigr.io/sidecar-pubsub-nats-auth-jwt: ""

    # Optional. Default "true"
    spawn-eigr.io/sidecar-delayed-invokes: "true"

    # Optional. Default "2"
    spawn-eigr.io/sidecar-crdt-sync-interval: "2"

    # Optional. Default "2"
    spawn-eigr.io/sidecar-crdt-ship-interval: "2"

    # Optional. Default "2"
    spawn-eigr.io/sidecar-crdt-ship-debounce: "2"

    # Optional. Default "60"
    spawn-eigr-io/sidecar-state-handoff-sync-interval: "60"

    # Optional. Default "crdt"
    spawn-eigr-io/supervisors-state-handoff-controller: "crdt"

    # Optional. Default "-1"
    spawn-eigr.io/actors-global-backpressure-max-demand: "-1"

    # Optional. Default "-1"
    spawn-eigr.io/actors-global-backpressure-min-demand: "-1"

    # Optional. Default "true"
    spawn-eigr.io/actors-global-backpressure-enabled: "true"
  """
  @impl true
  def manifest(resource, _opts \\ []), do: gen_configmap(resource)

  defp gen_configmap(
         %{
           system: system,
           namespace: ns,
           name: name,
           params: _params,
           labels: _labels,
           annotations: annotations
         } = _resource
       ) do
    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{
        "namespace" => ns,
        "name" => "#{name}-sidecar-cm"
      },
      "data" => %{
        "PROXY_APP_NAME" => name,
        "PROXY_HTTP_PORT" => annotations.proxy_http_port,
        "PROXY_HTTP_CLIENT_ADAPTER_POOL_SCHEDULERS" =>
          annotations.proxy_http_client_adapter_pool_schedulers,
        "PROXY_HTTP_CLIENT_ADAPTER_POOL_SIZE" => annotations.proxy_http_client_adapter_pool_size,
        "PROXY_HTTP_CLIENT_ADAPTER_POOL_MAX_IDLE_TIMEOUT" =>
          annotations.proxy_http_client_adapter_pool_max_idle_timeout,
        "PROXY_DEPLOYMENT_MODE" => annotations.proxy_mode,
        "PROXY_CLUSTER_POLLING" => annotations.cluster_poling_interval,
        "PROXY_CLUSTER_STRATEGY" => "kubernetes-dns",
        "PROXY_HEADLESS_SERVICE" => "system-#{system}",
        "PROXY_HOST_INTERFACE" => annotations.proxy_host_interface,
        "PROXY_UDS_ENABLED" => annotations.proxy_uds_enabled,
        "PROXY_UDS_ADDRESS" => annotations.proxy_uds_address,
        "USER_FUNCTION_HOST" => annotations.user_function_host,
        "USER_FUNCTION_PORT" => annotations.user_function_port,
        # TODO use secrets to storage nats configuration
        "SPAWN_DISABLE_METRICS" => annotations.metrics_disabled,
        "SPAWN_CONSOLE_METRICS" => annotations.metrics_log_console,
        "SPAWN_PUBSUB_ADAPTER" => annotations.pubsub_adapter,
        "SPAWN_PUBSUB_NATS_HOSTS" => annotations.pubsub_nats_hosts,
        "SPAWN_PUBSUB_NATS_AUTH" => annotations.pubsub_nats_auth,
        "SPAWN_PUBSUB_NATS_AUTH_TYPE" => annotations.pubsub_nats_auth_type,
        "SPAWN_PUBSUB_NATS_TLS" => annotations.pubsub_nats_tls,
        "SPAWN_PUBSUB_NATS_AUTH_USER" => annotations.pubsub_nats_auth_user,
        "SPAWN_PUBSUB_NATS_AUTH_PASS" => annotations.pubsub_nats_auth_pass,
        "SPAWN_PUBSUB_NATS_AUTH_JWT" => annotations.pubsub_nats_auth_jwt,
        "SPAWN_DELAYED_INVOKES" => annotations.delayed_invokes,
        "SPAWN_CRDT_SYNC_INTERVAL" => annotations.sync_interval,
        "SPAWN_CRDT_SHIP_INTERVAL" => annotations.ship_interval,
        "SPAWN_CRDT_SHIP_DEBOUNCE" => annotations.ship_debounce,
        "SPAWN_STATE_HANDOFF_SYNC_INTERVAL" => annotations.neighbours_sync_interval,
        "SPAWN_SUPERVISORS_STATE_HANDOFF_CONTROLLER" =>
          annotations.supervisors_state_handoff_controller,
        "ACTORS_GLOBAL_BACKPRESSURE_MAX_DEMAND" =>
          annotations.actors_global_backpressure_max_demand,
        "ACTORS_GLOBAL_BACKPRESSURE_MIN_DEMAND" =>
          annotations.actors_global_backpressure_min_demand,
        "ACTORS_GLOBAL_BACKPRESSURE_ENABLED" => annotations.actors_global_backpressure_enabled
      }
    }
  end
end
