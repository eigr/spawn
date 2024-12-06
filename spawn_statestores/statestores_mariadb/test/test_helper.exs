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

Application.put_env(
  :spawn_statestores,
  :database_projection_adapter,
  Statestores.Adapters.MariaDBProjectionAdapter
)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
