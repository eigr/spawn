ExUnit.start()

type = String.to_existing_atom(System.get_env("PROXY_DATABASE_TYPE", "mysql"))

adapter =
  case type do
    :mysql -> Statestores.Adapters.MySQL
    :postgres -> Statestores.Adapters.Postgres
  end

Ecto.Adapters.SQL.Sandbox.mode(adapter, :manual)
