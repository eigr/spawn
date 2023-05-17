defmodule Statestores.Adapters.Behaviour do
  @moduledoc """
  Defines the default behavior for each Statestore Provider.
  """
  alias Statestores.Schemas.Event

  @type id :: String.t()

  @type event :: Event.t()

  @callback get_by_key(id()) :: event()

  @callback save(event()) :: {:error, any} | {:ok, event()}

  @callback default_port :: <<_::32>>

  defmacro __using__(_opts) do
    quote do
      alias Statestores.Adapters.Behaviour
      import Statestores.Util, only: [get_default_database_port: 0, get_default_database_type: 0]

      @behaviour Statestores.Adapters.Behaviour

      def init(_type, config) do
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

        config =
          Keyword.put(config, :username, System.get_env("PROXY_DATABASE_USERNAME", "admin"))

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
            String.to_integer(System.get_env("PROXY_DATABASE_POOL_SIZE", "60"))
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
    end
  end
end
