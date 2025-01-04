import Config

config :spawn_operator,
  proxy_image: "ghcr.io/eigr/spawn-proxy:2.0.0-RC2"

config :bonny,
  # Add each Controller module for this operator to load here
  # Defaults to none. This *must* be set.
  controllers: [],

  # Function to call to get a K8s.Conn object.
  # The function should return a %K8s.Conn{} struct or a {:ok, %K8s.Conn{}} tuple
  get_conn: {SpawnOperator.K8sConn, :get, [config_env()]},

  # Set the Kubernetes API group for this operator.
  group: "spawn-eigr.io",

  # Name must only consist of only lowercase letters and hyphens.
  # Defaults to hyphenated mix app name
  operator_name: "spawn-operator",

  # Name must only consist of only lowercase letters and hyphens.
  # Defaults to hyphenated mix app name
  service_account_name: "spawn-operator",

  # Labels to apply to the operator's resources.
  labels: %{},

  # Operator deployment resources. These are the defaults.
  resources: %{limits: %{cpu: "200m", memory: "200Mi"}, requests: %{cpu: "200m", memory: "200Mi"}},
  manifest_override_callback: &Mix.Tasks.Bonny.Gen.Manifest.SpawnOperatorCustomizer.override/1

import_config "#{config_env()}.exs"
import_config "../../../config/config.exs"
