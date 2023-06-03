Application.put_env(
  :spawn_statestores,
  :database_adapter,
  Statestores.Adapters.PostgresSnapshotAdapter
)

Application.put_env(
  :spawn_statestores,
  :database_lookup_adapter,
  Statestores.Adapters.PostgresLookupAdapter
)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
