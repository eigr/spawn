Application.put_env(
  :spawn_statestores,
  :database_adapter,
  Statestores.Adapters.MSSQLSnapshotAdapter
)

Application.put_env(
  :spawn_statestores,
  :database_lookup_adapter,
  Statestores.Adapters.MSSQLLookupAdapter
)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
