Application.put_env(:spawn_statestores, :database_adapter, Statestores.Adapters.MySQL)

ExUnit.start()

Statestores.Supervisor.start_link(%{})
