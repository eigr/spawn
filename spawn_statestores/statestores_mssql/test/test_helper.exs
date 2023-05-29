Application.put_env(:spawn_statestores, :database_adapter, Statestores.Adapters.MSSQLSnapshotAdapter)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
