Application.put_env(
  :spawn_statestores,
  :database_adapter,
  Statestores.Adapters.MySQLSnapshotAdapter
)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
