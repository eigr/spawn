defmodule Actors.Config.Vapor do
  @behaviour Actors.Config

  require Logger
  alias Vapor.Provider.{Env, Dotenv}

  @impl true
  def load() do
    case Agent.start_link(fn -> %{} end, name: __MODULE__) do
      {:ok, _pid} ->
        Agent.get_and_update(__MODULE__, fn state ->
          if state == %{} do
            config = load_system_env()
            {config, config}
          else
            {state, state}
          end
        end)

      {:error, {:already_started, _pid}} ->
        Agent.get(__MODULE__, fn state -> state end)
    end
  end

  @impl true
  def get(key), do: Agent.get(__MODULE__, fn state -> Map.get(state, key) end)

  defp load_system_env() do
    providers = [
      %Dotenv{},
      %Env{
        bindings: [
          {:http_port, "PROXY_HTTP_PORT",
           default: 4000, map: &String.to_integer/1, required: false},
          {:grpc_port, "PROXY_GRPC_PORT",
           default: 5000, map: &String.to_integer/1, required: false},
          {:proxy_cluster_strategy, "PROXY_CLUSTER_STRATEGY", default: "gossip", required: false},
          {:proxy_headless_service, "PROXY_HEADLESS_SERVICE",
           default: "proxy-headless-svc", required: false},
          {:proxy_app_name, "PROXY_APP_NAME", default: "spawn-proxy", required: false},
          {:proxy_cluster_poling_interval, "PROXY_CLUSTER_POLLING",
           default: 3_000, map: &String.to_integer/1, required: false},
          {:user_function_host, "USER_FUNCTION_HOST", default: "0.0.0.0", required: false},
          {:user_function_port, "USER_FUNCTION_PORT",
           default: 8080, map: &String.to_integer/1, required: false},
          {:user_function_uds_enable, "PROXY_UDS_MODE", default: false, required: false},
          {:user_function_sock_addr, "PROXY_UDS_ADDRESS",
           default: "/var/run/cloudstate.sock", required: false},
          {:proxy_db_type, "PROXY_DATABASE_TYPE", default: "postgres", required: false},
          {:proxy_db_name, "PROXY_DATABASE_NAME", default: "eigr-functions-db", required: false},
          {:proxy_db_username, "PROXY_DATABASE_USERNAME", default: "admin", required: false},
          {:proxy_db_secret, "PROXY_DATABASE_SECRET", default: "admin", required: false},
          {:proxy_db_host, "PROXY_DATABASE_HOST", default: "localhost", required: false},
          {:proxy_db_port, "PROXY_DATABASE_PORT",
           default: 5432, map: &String.to_integer/1, required: false}
        ]
      }
    ]

    config = Vapor.load!(providers)

    Logger.info("Loading configs")

    Enum.each(config, fn {key, value} ->
      value_str = if String.contains?(Atom.to_string(key), "secret"), do: "****", else: value
      Logger.info("Loading config: [#{key}]:[#{value_str}]")
      Application.put_env(:spawn, key, value, persistent: true)
    end)

    config
  end
end
