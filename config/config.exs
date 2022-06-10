# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
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
  ecto_repos: [Statestores.Adapters.Store.MySQL, Statestores.Adapters.Store.Postgres]

config :statestores, Statestores.Adapters.Store.MySQL,
  database: "statestores_my_sql",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :statestores, Statestores.Adapters.Store.Postgres,
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

# (you should replace this with the name of your plug)
config :prometheus, Actors.Metrics.Exporter,
  path: "/metrics",
  ## or :protobuf, or :text
  format: :auto,
  registry: :default,
  auth: false

# App Configuration
config :proxy,
  http_port: System.get_env("PROXY_HTTP_PORT", "9001") |> String.to_integer()
