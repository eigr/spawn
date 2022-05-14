defmodule Spawn.Config.Vapor do
  @behaviour Spawn.Config

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
           default: "/var/run/cloudstate.sock", required: false}
        ]
      }
    ]

    config = Vapor.load!(providers)

    Enum.each(config, fn {key, value} ->
      Logger.debug("Loading config: [#{key}]:[#{value}]")
      Application.put_env(:toll_operator_proxy, key, value, persistent: true)
    end)

    config
  end
end
