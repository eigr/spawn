import Config

config :spawn_statestores, Statestores.Adapters.MariaDBSnapshotAdapter,
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: :infinity,
  pool_size: 24,
  prepare: :unnamed,
  queue_target: 5_000,
  queue_interval: 500

config :spawn_statestores, Statestores.Adapters.MariaDBProjectionAdapter,
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: :infinity,
  pool_size: 24,
  prepare: :unnamed,
  queue_target: 5_000,
  queue_interval: 500

config :spawn, http_node_client: NodeClientMock
