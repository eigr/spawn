defmodule Statestores.Util do
  @otp_app :spawn_statestores

  @type adapter :: term()

  @spec load_app :: :ok | {:error, any}
  def load_app do
    Application.load(@otp_app)
  end

  @spec load_adapter :: adapter()
  def load_adapter() do
    case Application.fetch_env(@otp_app, :database_adapter) do
      {:ok, value} ->
        value

      :error ->
        type =
          String.to_existing_atom(
            System.get_env("PROXY_DATABASE_TYPE", get_default_database_type())
          )

        load_adapter_by_type(type)
    end
  end

  def get_default_database_type do
    cond do
      Code.ensure_loaded?(Statestores.Adapters.MySQL) -> "mysql"
      Code.ensure_loaded?(Statestores.Adapters.CockroachDB) -> "cockroachdb"
      Code.ensure_loaded?(Statestores.Adapters.Postgres) -> "postgres"
      Code.ensure_loaded?(Statestores.Adapters.SQLite3) -> "sqlite"
      Code.ensure_loaded?(Statestores.Adapters.MSSQL) -> "mssql"
      true -> nil
    end
  end

  defp load_adapter_by_type(:mysql), do: Statestores.Adapters.MySQL

  defp load_adapter_by_type(:cockroachdb), do: Statestores.Adapters.CockroachDB

  defp load_adapter_by_type(:postgres), do: Statestores.Adapters.Postgres

  defp load_adapter_by_type(:sqlite), do: Statestores.Adapters.SQLite3

  defp load_adapter_by_type(:mssql), do: Statestores.Adapters.MSSQL

  @spec get_default_database_port :: <<_::32>>
  def get_default_database_port() do
    load_adapter().default_port()
  end
end
