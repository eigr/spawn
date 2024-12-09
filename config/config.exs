import Config

config :do_it, DoIt.Commfig,
  dirname: System.tmp_dir(),
  filename: "spawn_cli.json"

config :flame, :terminator,
  shutdown_timeout: :timer.minutes(3),
  failsafe_timeout: :timer.minutes(1),
  log: :debug

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
  truncate: 65536,
  level: :debug

#  compile_time_purge_matching: [
#    [level_lower_than: :info]
#  ]

# Our Console Backend-specific configuration
config :logger, :console,
  format: "$date $time [$node]:[$metadata]:[$level]:$message\n",
  metadata: [:pid, :span_id, :trace_id]

config :protobuf, extensions: :enabled

config :opentelemetry, :resource, service: %{name: "spawn"}

config :opentelemetry,
       :processors,
       otel_batch_processor: %{
         exporter: {:opentelemetry_exporter, %{endpoints: [{:http, ~c"localhost", 55681, []}]}}
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

config :mnesiac,
  stores: [Statestores.Adapters.Native.SnapshotStore],
  schema_type: :disc_copies,
  table_load_timeout: 600_000

import_config "#{config_env()}.exs"
