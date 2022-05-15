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

config :logger,
  backends: [:console],
  truncate: 65536,
  compile_time_purge_matching: [
    [level_lower_than: :debug]
  ]

# Our Console Backend-specific configuration
config :logger, :console,
  format: "$date $time [$node]:[$metadata]:[$level]:$levelpad$message\n",
  metadata: [:pid]

# hOOKS configuration
config :spawn,
  http_port: System.get_env("HTTP_PORT", "9001") |> String.to_integer(),
  broker_host: System.get_env("BROKER_HOST", "localhost"),
  broker_port: System.get_env("BROKER_PORT", "61613") |> String.to_integer(),
  broker_user: System.get_env("BROKER_USER", "admin"),
  broker_pass: System.get_env("BROKER_PASS", "admin")
