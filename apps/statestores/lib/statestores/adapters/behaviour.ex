defmodule Statestores.Adapters.Behaviour do
  alias Statestores.Schemas.Event

  @type actor :: String.t()

  @type event :: Event.t()

  @callback get_by_key(actor()) :: event()

  @callback save(event()) :: {:error, any} | {:ok, event()}

  defmacro __using__(_opts) do
    quote do
      alias Statestores.Adapters.Behaviour
      import Statestores.Util, only: [get_default_database_port: 0]

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

        config =
          Keyword.put(config, :hostname, System.get_env("PROXY_DATABASE_HOST", "localhost"))

        config =
          Keyword.put(
            config,
            :port,
            String.to_integer(System.get_env("PROXY_DATABASE_PORT", get_default_database_port()))
          )

        {:ok, config}
      end
    end
  end
end
