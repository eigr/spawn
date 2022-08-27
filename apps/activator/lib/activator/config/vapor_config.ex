defmodule Activator.Config.Vapor do
  @behaviour Activator.Config

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
          {:http_port, "ACTIVATOR_HTTP_PORT",
           default: 9091, map: &String.to_integer/1, required: false},
          {:proxy_cluster_strategy, "PROXY_CLUSTER_STRATEGY", default: "gossip", required: false},
          {:proxy_headless_service, "PROXY_HEADLESS_SERVICE",
           default: "proxy-headless-svc", required: false},
          {:proxy_app_name, "PROXY_APP_NAME", default: "spawn-proxy", required: false},
          {:proxy_cluster_poling_interval, "PROXY_CLUSTER_POLLING",
           default: 3_000, map: &String.to_integer/1, required: false},
          {:user_function_host, "USER_FUNCTION_HOST", default: "0.0.0.0", required: false},
          {:user_function_port, "USER_FUNCTION_PORT",
           default: 8090, map: &String.to_integer/1, required: false}
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
