defmodule Actors.Config.Vapor do
  @behaviour Actors.Config

  require Logger
  alias Vapor.Provider.{Env, Dotenv}

  @impl true
  def load(mod) do
    case Agent.start_link(fn -> %{} end, name: mod) do
      {:ok, _pid} ->
        Agent.get_and_update(mod, fn state ->
          if state == %{} do
            config = load_system_env()
            {config, config}
          else
            {state, state}
          end
        end)

      {:error, {:already_started, _pid}} ->
        Agent.get(mod, fn state -> state end)
    end
  end

  @impl true
  def get(mod, key), do: Agent.get(mod, fn state -> Map.get(state, key) end)

  defp load_system_env() do
    providers = [
      %Dotenv{},
      %Env{
        bindings: [
          {:app_name, "PROXY_APP_NAME", default: Config.Name.generate(), required: false},
          {:http_port, "PROXY_HTTP_PORT",
           default: 9001, map: &String.to_integer/1, required: false},
          {:deployment_mode, "PROXY_DEPLOYMENT_MODE", default: "sidecar", required: false},
          {:node_host_interface, "NODE_IP", default: "0.0.0.0", required: false},
          {:proxy_cluster_strategy, "PROXY_CLUSTER_STRATEGY", default: "gossip", required: false},
          {:proxy_headless_service, "PROXY_HEADLESS_SERVICE",
           default: "proxy-headless", required: false},
          {:proxy_cluster_polling_interval, "PROXY_CLUSTER_POLLING",
           default: 3_000, map: &String.to_integer/1, required: false},
          {:proxy_cluster_gossip_broadcast_only, "PROXY_CLUSTER_GOSSIP_BROADCAST_ONLY", default: "true", required: false},
          {:proxy_cluster_gossip_reuseaddr_address, "PROXY_CLUSTER_GOSSIP_REUSE_ADDRESS", default: "true", required: false},
          {:proxy_cluster_gossip_multicast_address, "PROXY_CLUSTER_GOSSIP_MULTICAST_ADDRESS", default: "255.255.255.255", required: false},
          {:proxy_uds_enable, "PROXY_UDS_ENABLED", default: false, required: false},
          {:proxy_sock_addr, "PROXY_UDS_ADDRESS",
           default: "/var/run/spawn.sock", required: false},
          {:proxy_host_interface, "POD_IP", default: "0.0.0.0", required: false},
          {:proxy_disable_metrics, "SPAWN_DISABLE_METRICS", default: "false", required: false},
          {:proxy_console_metrics, "SPAWN_CONSOLE_METRICS", default: "false", required: false},
          {:user_function_host, "USER_FUNCTION_HOST", default: "0.0.0.0", required: false},
          {:user_function_port, "USER_FUNCTION_PORT",
           default: 8090, map: &String.to_integer/1, required: false},
          {:pubsub_adapter, "SPAWN_PUBSUB_ADAPTER", default: "native", required: false},
          {:pubsub_adapter_nats_hosts, "SPAWN_PUBSUB_NATS_HOSTS",
           default: "nats://127.0.0.1:4222", required: false},
          {:pubsub_adapter_nats_tls, "SPAWN_PUBSUB_NATS_TLS", default: "false", required: false},
          {:pubsub_adapter_nats_auth, "SPAWN_PUBSUB_NATS_AUTH",
           default: "false", required: false},
          {:pubsub_adapter_nats_auth_type, "SPAWN_PUBSUB_NATS_AUTH_TYPE",
           default: "simple", required: false},
          {:pubsub_adapter_nats_auth_user, "SPAWN_PUBSUB_NATS_AUTH_USER",
           default: "admin", required: false},
          {:pubsub_adapter_nats_auth_pass, "SPAWN_PUBSUB_NATS_AUTH_PASS",
           default: "admin", required: false},
          {:pubsub_adapter_nats_auth_jwt, "SPAWN_PUBSUB_NATS_AUTH_JWT",
           default: "", required: false}
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
