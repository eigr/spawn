Application.put_env(
  :spawn_statestores,
  :database_adapter,
  Statestores.Adapters.SQLite3SnapshotAdapter
)

Application.put_env(
  :spawn_statestores,
  :database_lookup_adapter,
  Statestores.Adapters.SQLite3LookupAdapter
)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
