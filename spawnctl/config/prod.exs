import Config

config :logger,
  backends: [:console],
  truncate: 65536,
  level: :info,
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

# Our Console Backend-specific configuration
config :logger, :console,
  format: "$date $time [$node]:[$metadata]:[$level]:$message\n",
  metadata: [:pid, :span_id, :trace_id]
