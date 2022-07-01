defmodule Statestores.Util do
  @otp_app :statestores

  def load_app do
    Application.load(@otp_app)
  end

  def load_repo() do
    type = String.to_existing_atom(System.get_env("PROXY_DATABASE_TYPE", "mysql"))
    load_repo(type)
  end

  def load_repo(:mysql), do: Statestores.Adapters.MySQL

  def load_repo(:postgres), do: Statestores.Adapters.Postgres

  def get_default_database_port() do
    String.to_existing_atom(System.get_env("PROXY_DATABASE_TYPE", "mysql"))
    |> get_default_database_port()
  end

  def get_default_database_port(:mysql), do: "3306"

  def get_default_database_port(:postgres), do: "5432"
end
