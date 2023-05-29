Application.put_env(
  :spawn_statestores,
  :database_adapter,
  Statestores.Adapters.MySQLSnapshotAdapter
)

Application.put_env(
  :spawn_statestores,
  :database_lookup_adapter,
  Statestores.Adapters.MySQLLookupAdapter
)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
