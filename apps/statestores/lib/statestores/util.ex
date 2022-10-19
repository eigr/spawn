defmodule Statestores.Util do
  @otp_app :statestores

  @spec load_app :: :ok | {:error, any}
  def load_app do
    Application.load(@otp_app)
  end

  @spec load_repo ::
          Statestores.Adapters.MySQL
          | Statestores.Adapters.Postgres
          | Statestores.Adapters.SQLite3
          | Statestores.Adapters.MSSQL
  def load_repo() do
    type = String.to_existing_atom(System.get_env("PROXY_DATABASE_TYPE", "mysql"))
    load_repo(type)
  end

  @spec load_repo(:mysql | :postgres | :sqlite) ::
          Statestores.Adapters.MySQL | Statestores.Adapters.Postgres
  def load_repo(:mysql), do: Statestores.Adapters.MySQL

  def load_repo(:postgres), do: Statestores.Adapters.Postgres

  def load_repo(:sqlite), do: Statestores.Adapters.SQLite3

  def load_repo(:mssql), do: Statestores.Adapters.MSSQL

  @spec get_default_database_port :: <<_::32>>
  def get_default_database_port() do
    String.to_existing_atom(System.get_env("PROXY_DATABASE_TYPE", "mysql"))
    |> get_default_database_port()
  end

  @spec get_default_database_port(:mysql | :postgres) :: <<_::32>>
  def get_default_database_port(:mysql), do: "3306"

  def get_default_database_port(:postgres), do: "5432"

  def get_default_database_port(:sqlite), do: "0"

  def get_default_database_port(:mssql), do: "1433"
end
