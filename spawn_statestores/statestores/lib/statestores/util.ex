defmodule Statestores.Util do
  @moduledoc false
  require Logger

  @otp_app :spawn_statestores

  @type adapter :: term()

  @spec load_app :: :ok | {:error, any}
  def load_app do
    Application.load(@otp_app)
  end

  def create_directory(path) do
    case File.stat(path) do
      {:ok, %File.Stat{type: :directory}} ->
        Logger.debug("Directory already exists: #{path}")

      {:error, :enoent} ->
        case File.mkdir_p(path) do
          :ok ->
            Logger.debug("Directory created: #{path}")

          {:error, reason} ->
            Logger.error("Failed to create directory: #{reason}")
        end

      {:ok, _} ->
        Logger.warning("Path exists but is not a directory: #{path}")

      {:error, reason} ->
        Logger.error("Error checking path: #{reason}")
    end
  end

  def supervisor_process_logger(module) do
    %{
      id: Module.concat([module, Logger]),
      start:
        {Task, :start,
         [
           fn ->
             Process.flag(:trap_exit, true)

             Logger.info("[SUPERVISOR] #{inspect(module)} is up")

             receive do
               {:EXIT, _pid, reason} ->
                 Logger.info(
                   "[SUPERVISOR] #{inspect(module)}:#{inspect(self())} is successfully down with reason #{inspect(reason)}"
                 )

                 :ok
             end
           end
         ]}
    }
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

  @spec load_projection_adapter :: adapter()
  def load_projection_adapter() do
    case Application.fetch_env(@otp_app, :projection_adapter) do
      {:ok, value} ->
        value

      :error ->
        type =
          String.to_existing_atom(
            System.get_env("PROXY_DATABASE_TYPE", get_default_database_type())
          )

        load_projection_adapter_by_type(type)
    end
  end

  def get_default_database_type do
    cond do
      Code.ensure_loaded?(Statestores.Adapters.PostgresSnapshotAdapter) -> "postgres"
      Code.ensure_loaded?(Statestores.Adapters.MariaDBSnapshotAdapter) -> "mariadb"
      Code.ensure_loaded?(Statestores.Adapters.NativeSnapshotAdapter) -> "native"
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

    hostname = System.get_env("PROXY_DATABASE_HOST", "127.0.0.1")

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
        String.to_integer(System.get_env("PROXY_DATABASE_POOL_SIZE", "50"))
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

  @spec generate_key(any()) :: integer()
  def generate_key(id), do: :erlang.phash2({id.name, id.system})

  def get_statestore_key do
    key =
      System.get_env(
        "SPAWN_STATESTORE_KEY",
        Base.encode64(Application.get_env(:spawn_statestores, :statestore_key, ""))
      )
      |> Base.decode64!()

    if key == "" do
      raise "Missing SPAWN_STATESTORE_KEY environment variable."
    end

    key
  end

  def normalize_table_name(nil), do: {:error, "Table name cannot be nil"}
  def normalize_table_name(name) when is_binary(name) do
    name
    |> Macro.underscore() # Converts "CamelCase" to "snake_case"
    |> String.downcase() # Ensures the name is all lowercase
  end

  # Lookup Adapters
  defp load_lookup_adapter_by_type(:mariadb), do: Statestores.Adapters.MariaDBLookupAdapter

  defp load_lookup_adapter_by_type(:postgres), do: Statestores.Adapters.PostgresLookupAdapter

  defp load_lookup_adapter_by_type(:native), do: Statestores.Adapters.NativeLookupAdapter

  # Snapshot Adapters
  defp load_snapshot_adapter_by_type(:mariadb), do: Statestores.Adapters.MariaDBSnapshotAdapter

  defp load_snapshot_adapter_by_type(:postgres), do: Statestores.Adapters.PostgresSnapshotAdapter

  defp load_snapshot_adapter_by_type(:native), do: Statestores.Adapters.NativeSnapshotAdapter

  # Projections Adapters
  defp load_projection_adapter_by_type(:mariadb),
    do: Statestores.Adapters.MariaDBProjectionAdapter

  defp load_projection_adapter_by_type(:postgres),
    do: Statestores.Adapters.PostgresProjectionAdapter

  defp load_projection_adapter_by_type(:native),
    do: nil
end
