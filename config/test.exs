import Config

config :statestores, Statestores.Adapters.MySQL, pool: Ecto.Adapters.SQL.Sandbox

config :bonny,
  get_conn: {K8s.Conn, :from_file, ["~/.kube/config", [context: "minikube"]]},

  # Add each CRD Controller module for this operator to load here
  controllers: [
    Operator.Controllers.V1.Activator,
    Operator.Controllers.V1.ActorNode,
    Operator.Controllers.V1.ActorSystem
  ],

  # The namespace to watch for Namespaced CRDs.
  # Defaults to "default". `:all` for all namespaces
  # Also configurable via environment variable `BONNY_POD_NAMESPACE`
  namespace: :all,

  #   # Set the Kubernetes API group for this operator.
  #   # This can be overwritten using the @group attribute of a controller
  #   group: "your-operator.example.com",

  #   # Name must only consist of only lowercase letters and hyphens.
  #   # Defaults to hyphenated mix app name
  operator_name: "eigr-functions-controller",

  #   # Name must only consist of only lowercase letters and hyphens.
  #   # Defaults to hyphenated mix app name
  service_account_name: "eigr-functions",

  #   # Labels to apply to the operator's resources.
  labels: %{
    eigr_functions_protocol_minor_version: "1",
    eigr_functions_protocol_major_version: "0",
    proxy_name: "spawn"
  },

  #   # Operator deployment resources. These are the defaults.
  resources: %{
    limits: %{cpu: "500m", memory: "1024Mi"},
    requests: %{cpu: "100m", memory: "100Mi"}
  }
