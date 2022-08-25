import Config

# config :statestores, Statestores.Vault,
# json_library: Jason,
# ciphers: [
#  default:
#    {Cloak.Ciphers.AES.GCM,
#     tag: "AES.GCM.V1",
#     key: Base.decode64!("3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE="),
#     iv_length: 12},
#  secondary:
#    {Cloak.Ciphers.AES.CTR,
#     tag: "AES.CTR.V1", key: Base.decode64!("o5IzV8xlunc0m0/8HNHzh+3MCBBvYZa0mv4CsZic5qI=")}
#  ]

config :statestores,
  ecto_repos: [Statestores.Adapters.MySQL, Statestores.Adapters.Postgres]

config :statestores, Statestores.Adapters.MySQL,
  database: "statestores_my_sql",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :statestores, Statestores.Adapters.Postgres,
  database: "statestores_postgres",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :logger,
  backends: [:console],
  truncate: 65536

# ,
# compile_time_purge_matching: [
#  [level_lower_than: :debug]
# ]

# Our Console Backend-specific configuration
config :logger, :console,
  format: "$date $time [$node]:[$metadata]:[$level]:$levelpad$message\n",
  metadata: [:pid]

config :protobuf, extensions: :enabled

config :prometheus, MetricsEndpoint.Exporter,
  path: "/metrics",
  format: :auto,
  registry: :default,
  auth: false

# App Configuration
config :proxy,
  http_port: System.get_env("PROXY_HTTP_PORT", "9001") |> String.to_integer()

# config :bonny,
#   get_conn: {K8s.Conn, :from_file, ["~/.kube/config", [context: "kind-default"]]}

# config :bonny,
#   Add each CRD Controller module for this operator to load here
#   controllers: [
#     Operator.Controllers.V1.Activator,
#     Operator.Controllers.V1.ActorNode,
#     Operator.Controllers.V1.ActorSystem
#   ],
#   namespace: :all,

#     # Set the Kubernetes API group for this operator.
#     # This can be overwritten using the @group attribute of a controller
#     group: "your-operator.example.com",

#     # Name must only consist of only lowercase letters and hyphens.
#     # Defaults to hyphenated mix app name
#   operator_name: "eigr-functions-controller",

#     # Name must only consist of only lowercase letters and hyphens.
#     # Defaults to hyphenated mix app name
#     service_account_name: "your-operator",

#     # Labels to apply to the operator's resources.
#   labels: %{
#     eigr_functions_protocol_minor_version: "1",
#     eigr_functions_protocol_major_version: "0",
#     proxy_name: "spawn"
#   },

#     # Operator deployment resources. These are the defaults.
#   resources: %{
#     limits: %{cpu: "500m", memory: "1024Mi"},
#     requests: %{cpu: "100m", memory: "100Mi"}
#   }

import_config "#{config_env()}.exs"
