defmodule Statestores.Util do
  @moduledoc false
  @otp_app :spawn_statestores

  @type adapter :: term()

  @spec load_app :: :ok | {:error, any}
  def load_app do
    Application.load(@otp_app)
  end

  @spec load_lookup_adapter :: adapter()
  def load_lookup_adapter() do
    case Application.fetch_env(@otp_app, :database_lookup_adapter) do
      {:ok, value} ->
        value

      :error ->
        type =
          String.to_existing_atom(
            System.get_env("PROXY_DATABASE_TYPE", get_default_database_type())
          )

        load_lookup_adapter_by_type(type)
    end
  end

  @spec load_snapshot_adapter :: adapter()
  def load_snapshot_adapter() do
    case Application.fetch_env(@otp_app, :database_adapter) do
      {:ok, value} ->
        value

      :error ->
        type =
          String.to_existing_atom(
            System.get_env("PROXY_DATABASE_TYPE", get_default_database_type())
          )

        load_snapshot_adapter_by_type(type)
    end
  end

  def get_default_database_type do
    cond do
      Code.ensure_loaded?(Statestores.Adapters.MySQLSnapshotAdapter) -> "mysql"
      Code.ensure_loaded?(Statestores.Adapters.CockroachDBSnapshotAdapter) -> "cockroachdb"
      Code.ensure_loaded?(Statestores.Adapters.PostgresSnapshotAdapter) -> "postgres"
      Code.ensure_loaded?(Statestores.Adapters.SQLite3SnapshotAdapter) -> "sqlite"
      Code.ensure_loaded?(Statestores.Adapters.MSSQLSnapshotAdapter) -> "mssql"
      true -> nil
    end
  end

  def init_config(config) do
    config =
      case System.get_env("MIX_ENV") do
        "test" -> Keyword.put(config, :pool, Ecto.Adapters.SQL.Sandbox)
        _ -> config
      end

    config =
      Keyword.put(
        config,
        :database,
        System.get_env("PROXY_DATABASE_NAME", "eigr-functions-db")
      )

    config = Keyword.put(config, :username, System.get_env("PROXY_DATABASE_USERNAME", "admin"))

    config = Keyword.put(config, :password, System.get_env("PROXY_DATABASE_SECRET", "admin"))

    hostname = System.get_env("PROXY_DATABASE_HOST", "localhost")

    config = Keyword.put(config, :hostname, hostname)
    config = Keyword.put(config, :migration_lock, nil)

    config =
      Keyword.put(
        config,
        :port,
        String.to_integer(System.get_env("PROXY_DATABASE_PORT", get_default_database_port()))
      )

    config =
      Keyword.put(
        config,
        :pool_size,
        String.to_integer(System.get_env("PROXY_DATABASE_POOL_SIZE", "30"))
      )

    config =
      Keyword.put(
        config,
        :queue_target,
        String.to_integer(System.get_env("PROXY_DATABASE_QUEUE_TARGET", "10000"))
      )

    use_ssl? = System.get_env("PROXY_DATABASE_SSL", "false") == "true"
    ssl_verify_peer? = System.get_env("PROXY_DATABASE_SSL_VERIFY", "false") == "true"

    config =
      Keyword.put(
        config,
        :ssl,
        use_ssl?
      )

    config =
      cond do
        use_ssl? and ssl_verify_peer? ->
          Keyword.put(config, :ssl_opts,
            verify: :verify_peer,
            cacertfile: CAStore.file_path(),
            server_name_indication: String.to_charlist(hostname),
            customize_hostname_check: [
              match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
            ]
          )

        use_ssl? ->
          Keyword.put(config, :ssl_opts, verify: :verify_none)

        true ->
          config
      end

    {:ok, config}
  end

  @spec get_default_database_port :: <<_::32>>
  def get_default_database_port() do
    load_snapshot_adapter().default_port()
  end

  @spec generate_key(any()) :: String.t()
  def generate_key(id), do: :erlang.phash2({id.name, id.system})

  # Lookup Adapters
  defp load_lookup_adapter_by_type(:mysql), do: Statestores.Adapters.MySQLLookupAdapter

  defp load_lookup_adapter_by_type(:cockroachdb),
    do: Statestores.Adapters.CockroachDBLookupAdapter

  defp load_lookup_adapter_by_type(:postgres), do: Statestores.Adapters.PostgresLookupAdapter

  defp load_lookup_adapter_by_type(:sqlite), do: Statestores.Adapters.SQLite3LookupAdapter

  defp load_lookup_adapter_by_type(:mssql), do: Statestores.Adapters.MSSQLLookupAdapter

  # Snapshot Adapters
  defp load_snapshot_adapter_by_type(:mysql), do: Statestores.Adapters.MySQLSnapshotAdapter

  defp load_snapshot_adapter_by_type(:cockroachdb),
    do: Statestores.Adapters.CockroachDBSnapshotAdapter

  defp load_snapshot_adapter_by_type(:postgres), do: Statestores.Adapters.PostgresSnapshotAdapter

  defp load_snapshot_adapter_by_type(:sqlite), do: Statestores.Adapters.SQLite3SnapshotAdapter

  defp load_snapshot_adapter_by_type(:mssql), do: Statestores.Adapters.MSSQLSnapshotAdapter
end
