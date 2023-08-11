Application.put_env(
  :spawn_statestores,
  :database_adapter,
  Statestores.Adapters.MariaDBSnapshotAdapter
)

Application.put_env(
  :spawn_statestores,
  :database_lookup_adapter,
  Statestores.Adapters.MariaDBLookupAdapter
)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
