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
end
