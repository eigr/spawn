import Config

config :logger,
  backends: [:console],
  truncate: 65536,
  level: :debug

# Our Console Backend-specific configuration
config :logger, :console,
  format: "$date $time [$node]:[$metadata]:[$level]:$message\n",
  metadata: [:pid, :span_id, :trace_id]

config :do_it, DoIt.Commfig,
  dirname: System.user_home(),
  filename: "spawn_cli.json"
