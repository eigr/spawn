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

Application.put_env(
  :spawn_statestores,
  :database_projection_adapter,
  Statestores.Adapters.PostgresProjectionAdapter
)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
