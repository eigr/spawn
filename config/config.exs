import Config

config :do_it, DoIt.Commfig,
  dirname: System.tmp_dir(),
  filename: "spawn_cli.json"

# config :spawn_statestores, Statestores.Vault,
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

config :logger,
  backends: [:console],
  truncate: 65536

# level: :info

#  compile_time_purge_matching: [
#    [level_lower_than: :info]
#  ]

# Our Console Backend-specific configuration
config :logger, :console,
  format: "$date $time [$node]:[$metadata]:[$level]:$message\n",
  metadata: [:pid, :span_id, :trace_id]

config :protobuf, extensions: :enabled

# config :prometheus, MetricsEndpoint.Exporter,
#  path: "/metrics",
#  format: :auto,
#  registry: :default,
#  auth: false

config :opentelemetry, :resource, service: %{name: "spawn"}

# config :opentelemetry,
#   span_processor: :batch,
#   traces_exporter: {:otel_exporter_stdout, []}
#   #traces_exporter: {:otel_exporter_stdout, []}

config :opentelemetry,
       :processors,
       otel_batch_processor: %{
         exporter: {:opentelemetry_exporter, %{endpoints: [{:http, 'localhost', 55681, []}]}}
       }

config :spawn,
  acl_manager: Actors.Security.Acl.DefaultAclManager,
  split_brain_detector: Actors.Node.DefaultSplitBrainDetector

config :spawn, Spawn.Cache.LookupCache,
  backend: :shards,
  partitions: System.schedulers_online(),
  gc_interval: :timer.hours(12),
  max_size: 1_000_000,
  allocated_memory: 2_000_000_000,
  gc_cleanup_min_timeout: :timer.seconds(60),
  gc_cleanup_max_timeout: :timer.minutes(10)

import_config "#{config_env()}.exs"
