Application.put_env(:spawn_statestores, :database_adapter, Statestores.Adapters.SQLite3)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
