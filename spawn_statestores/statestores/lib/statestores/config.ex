defmodule Statestores.Config do
  require Logger
  alias Vapor.Provider.{Env, Dotenv}

  def load() do
    providers = [
      %Dotenv{},
      %Env{
        bindings: [
          {:proxy_db_type, "PROXY_DATABASE_TYPE", default: "postgres", required: false},
          {:proxy_db_name, "PROXY_DATABASE_NAME", default: "eigr-functions-db", required: false},
          {:proxy_db_username, "PROXY_DATABASE_USERNAME", default: "admin", required: false},
          {:proxy_db_secret, "PROXY_DATABASE_SECRET", default: "admin", required: false},
          {:proxy_db_host, "PROXY_DATABASE_HOST", default: "localhost", required: false},
          {:proxy_db_port, "PROXY_DATABASE_PORT", default: 5432, map: &String.to_integer/1, required: false}
        ]
      }
    ]

    config = Vapor.load!(providers)

    Logger.info("[Statestores.Config] Loading configs")

    Enum.each(config, fn {key, value} ->
      value_str = if String.contains?(Atom.to_string(key), "secret"), do: "****", else: value
      Logger.info("[Statestores.Config] Loading config: [#{key}]:[#{value_str}]")
      Application.put_env(:spawn, key, value, persistent: true)
    end)

    config
  end
end
