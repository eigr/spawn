Application.put_env(
  :spawn_statestores,
  :database_adapter,
  Statestores.Adapters.NativeSnapshotAdapter
)

Application.put_env(
  :spawn_statestores,
  :database_lookup_adapter,
  Statestores.Adapters.NativeLookupAdapter
)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
