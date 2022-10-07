import Config

config :statestores, Statestores.Adapters.MySQL,
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: :infinity,
  pool_size: 24,
  prepare: :unnamed,
  queue_target: 5_000,
  queue_interval: 500
