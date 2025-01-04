defmodule SpawnOperator do
  @moduledoc """
  Documentation for `SpawnOperator`.
  """
  require Logger

  @actorsystem_apiversion_key "spawn-eigr.io/actor-system"
  @actorsystem_default_name "spawn-system"

  def get_args(resource) do
    _metadata = K8s.Resource.metadata(resource)
    labels = K8s.Resource.labels(resource)
    resource_annotations = K8s.Resource.annotations(resource)
    annotations = get_annotations_or_defaults(resource_annotations)

    ns = K8s.Resource.namespace(resource) || "default"
    name = K8s.Resource.name(resource)
    system = annotations.actor_system

    spec = Map.get(resource, "spec")

    %{
      system: system,
      namespace: ns,
      name: name,
      params: spec,
      labels: labels,
      annotations: annotations
    }
  end

  def get_annotations_or_defaults(annotations) do
    %{
      actor_system: Map.get(annotations, @actorsystem_apiversion_key, @actorsystem_default_name),
      user_function_host: Map.get(annotations, "spawn-eigr.io/app-host", "0.0.0.0"),
      user_function_port: Map.get(annotations, "spawn-eigr.io/app-port", "8090"),
      cluster_poling_interval:
        Map.get(annotations, "spawn-eigr.io/cluster-poling-interval", "3000"),
      logger_level: Map.get(annotations, "spawn-eigr.io/sidecar-logger-level", "info"),
      proxy_mode: Map.get(annotations, "spawn-eigr.io/sidecar-mode", "sidecar"),
      proxy_http_port: Map.get(annotations, "spawn-eigr.io/sidecar-http-port", "9001"),
      proxy_http_client_adapter_pool_schedulers:
        Map.get(annotations, "spawn-eigr.io/sidecar-http-pool-count", "8"),
      proxy_http_client_adapter_pool_size:
        Map.get(annotations, "spawn-eigr.io/sidecar-http-pool-size", "30"),
      proxy_http_client_adapter_pool_max_idle_timeout:
        Map.get(annotations, "spawn-eigr.io/sidecar-http-pool-max-idle-timeout", "1000"),
      proxy_host_interface: Map.get(annotations, "spawn-eigr.io/sidecar-address", "0.0.0.0"),
      proxy_image_tag:
        Map.get(
          annotations,
          "spawn-eigr.io/sidecar-image-tag",
          "ghcr.io/eigr/spawn-proxy:2.0.0-RC2"
        ),
      proxy_init_container_image_tag:
        Map.get(
          annotations,
          "spawn-eigr.io/sidecar-init-container-image-tag",
          "ghcr.io/eigr/spawn-initializer:2.0.0-RC2"
        ),
      proxy_uds_enabled: Map.get(annotations, "spawn-eigr.io/sidecar-uds-enabled", "false"),
      proxy_uds_address:
        Map.get(annotations, "spawn-eigr.io/sidecar-uds-socket-path", "/var/run/spawn.sock"),
      metrics_port: Map.get(annotations, "spawn-eigr.io/sidecar-metrics-port", "9001"),
      metrics_disabled: Map.get(annotations, "spawn-eigr.io/sidecar-metrics-disabled", "false"),
      metrics_log_console:
        Map.get(annotations, "spawn-eigr.io/sidecar-metrics-log-console", "true"),
      pubsub_adapter: Map.get(annotations, "spawn-eigr.io/sidecar-pubsub-adapter", "native"),
      pubsub_nats_hosts:
        Map.get(annotations, "spawn-eigr.io/sidecar-pubsub-nats-hosts", "nats://127.0.0.1:4222"),
      pubsub_nats_tls: Map.get(annotations, "spawn-eigr.io/sidecar-pubsub-nats-tls", "false"),
      pubsub_nats_auth_type:
        Map.get(annotations, "spawn-eigr.io/sidecar-pubsub-nats-auth-type", "simple"),
      pubsub_nats_auth: Map.get(annotations, "spawn-eigr.io/sidecar-pubsub-nats-auth", "false"),
      pubsub_nats_auth_jwt:
        Map.get(annotations, "spawn-eigr.io/sidecar-pubsub-nats-auth-jwt", ""),
      pubsub_nats_auth_user:
        Map.get(annotations, "spawn-eigr.io/sidecar-pubsub-nats-auth-user", "admin"),
      pubsub_nats_auth_pass:
        Map.get(annotations, "spawn-eigr.io/sidecar-pubsub-nats-auth-pass", "admin"),
      delayed_invokes: Map.get(annotations, "spawn-eigr.io/sidecar-delayed-invokes", "true"),
      sync_interval: Map.get(annotations, "spawn-eigr.io/sidecar-crdt-sync-interval", "2"),
      ship_interval: Map.get(annotations, "spawn-eigr.io/sidecar-crdt-ship-interval", "2"),
      ship_debounce: Map.get(annotations, "spawn-eigr.io/sidecar-crdt-ship-debounce", "2"),
      neighbours_sync_interval:
        Map.get(annotations, "spawn-eigr.io/sidecar-state-handoff-sync-interval", "60000"),
      supervisors_state_handoff_controller:
        Map.get(annotations, "spawn-eigr.io/supervisors-state-handoff-controller", "crdt"),
      actors_global_backpressure_max_demand:
        Map.get(annotations, "spawn-eigr.io/actors-global-backpressure-max-demand", "-1"),
      actors_global_backpressure_min_demand:
        Map.get(annotations, "spawn-eigr.io/actors-global-backpressure-min-demand", "-1"),
      actors_global_backpressure_enabled:
        Map.get(annotations, "spawn-eigr.io/actors-global-backpressure-enabled", "true")
    }
  end
end
