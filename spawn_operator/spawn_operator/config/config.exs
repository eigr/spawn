import Config

config :bonny,
  # Add each Controller module for this operator to load here
  # Defaults to none. This *must* be set.
  controllers: [
    SpawnOperator.Controller.ActorSystemController,
    SpawnOperator.Controller.ActorHostController,
    SpawnOperator.Controller.ActivatorController
  ],

  # Function to call to get a K8s.Conn object.
  # The function should return a %K8s.Conn{} struct or a {:ok, %K8s.Conn{}} tuple
  get_conn: {SpawnOperator.K8sConn, :get, [config_env()]},

  # The namespace to watch for Namespaced CRDs.
  # Defaults to "default". `:all` for all namespaces
  # Also configurable via environment variable `BONNY_POD_NAMESPACE`
  namespace: :all,

  # Set the Kubernetes API group for this operator.
  group: "spawn-eigr.io",

  # Set the Kubernetes API versions for this operator.
  # This should be written in Elixir module form, e.g. YourOperator.API.V1 or YourOperator.API.V1Alpha1:
  versions: [
    SpawnOperator.Versions.Api.V1.Activator,
    SpawnOperator.Versions.Api.V1.ActorHost,
    SpawnOperator.Versions.Api.V1.ActorSystem
  ],

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
