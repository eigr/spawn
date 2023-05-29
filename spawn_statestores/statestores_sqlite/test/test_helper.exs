Application.put_env(:spawn_statestores, :database_adapter, Statestores.Adapters.SQLite3SnapshotAdapter)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
