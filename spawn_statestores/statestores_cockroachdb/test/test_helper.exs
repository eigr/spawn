Application.put_env(
  :spawn_statestores,
  :database_adapter,
  Statestores.Adapters.CockroachDBSnapshotAdapter
)

Application.put_env(
  :spawn_statestores,
  :database_lookup_adapter,
  Statestores.Adapters.CockroachDBLookupAdapter
)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
