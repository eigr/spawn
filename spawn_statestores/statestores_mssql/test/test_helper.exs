Application.put_env(:spawn_statestores, :database_adapter, Statestores.Adapters.MSSQL)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
