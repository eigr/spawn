defmodule Actors.Config.Vapor do
  @moduledoc """
  `Config.Vapor` Implements the `Config` behavior
  to allow the retrieval of system variables
  that will be included in the system configuration.
  """
  require Logger
  alias Vapor.Provider.{Env, Dotenv}
  import Statestores.Util, only: [load_lookup_adapter: 0]

  @behaviour Actors.Config

  @default_actor_system_name "spawn-system"

  @impl true
  def load(mod) do
    case Agent.start_link(fn -> %{} end, name: mod) do
      {:ok, _pid} ->
        Agent.get_and_update(mod, fn state ->
          update_state(state)
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
          {:actor_system_name, "PROXY_ACTOR_SYSTEM_NAME",
           default: @default_actor_system_name, required: false},
          {:http_port, "PROXY_HTTP_PORT",
           default: 9001, map: &String.to_integer/1, required: false},
          {:proxy_http_client_adapter, "PROXY_HTTP_CLIENT_ADAPTER",
           default: "finch", required: false},
          {:deployment_mode, "PROXY_DEPLOYMENT_MODE", default: "sidecar", required: false},
          {:node_host_interface, "NODE_IP", default: "0.0.0.0", required: false},
          {:proxy_cluster_strategy, "PROXY_CLUSTER_STRATEGY", default: "gossip", required: false},
          {:proxy_headless_service, "PROXY_HEADLESS_SERVICE",
           default: "proxy-headless", required: false},
          {:proxy_cluster_polling_interval, "PROXY_CLUSTER_POLLING",
           default: 3_000, map: &String.to_integer/1, required: false},
          {:proxy_cluster_gossip_broadcast_only, "PROXY_CLUSTER_GOSSIP_BROADCAST_ONLY",
           default: "true", required: false},
          {:proxy_cluster_gossip_reuseaddr_address, "PROXY_CLUSTER_GOSSIP_REUSE_ADDRESS",
           default: "true", required: false},
          {:proxy_cluster_gossip_multicast_address, "PROXY_CLUSTER_GOSSIP_MULTICAST_ADDRESS",
           default: "255.255.255.255", required: false},
          {:proxy_uds_enable, "PROXY_UDS_ENABLED", default: false, required: false},
          {:proxy_sock_addr, "PROXY_UDS_ADDRESS",
           default: "/var/run/spawn.sock", required: false},
          {:proxy_host_interface, "POD_IP", default: "0.0.0.0", required: false},
          {:proxy_disable_metrics, "SPAWN_DISABLE_METRICS", default: "false", required: false},
          {:proxy_console_metrics, "SPAWN_CONSOLE_METRICS", default: "false", required: false},
          {:user_function_host, "USER_FUNCTION_HOST", default: "0.0.0.0", required: false},
          {:user_function_port, "USER_FUNCTION_PORT",
           default: 8090, map: &String.to_integer/1, required: false},

          # Supervisors configuration
          {:state_handoff_controller_adapter, "SPAWN_SUPERVISORS_STATE_HANDOFF_CONTROLLER",
           default: "persistent", required: false},
          {:state_handoff_manager_pool_size, "SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_POOL_SIZE",
           default: 20, map: &String.to_integer/1, required: false},
          {:state_handoff_manager_call_timeout,
           "SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_CALL_TIMEOUT",
           default: 60000, map: &String.to_integer/1, required: false},
          {:state_handoff_manager_call_pool_min,
           "SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_CALL_POOL_MIN",
           default: 0, map: &String.to_integer/1, required: false},
          {:state_handoff_manager_call_pool_max,
           "SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_CALL_POOL_MAX",
           default: -1, map: &String.to_integer/1, required: false},
          {:actors_max_restarts, "SPAWN_SUPERVISORS_ACTORS_MAX_RESTARTS",
           default: 10000, map: &String.to_integer/1, required: false},
          {:actors_max_seconds, "SPAWN_SUPERVISORS_ACTORS_MAX_SECONDS",
           default: 3600, map: &String.to_integer/1, required: false},
          {:state_handoff_max_restarts, "SPAWN_SUPERVISORS_STATE_HANDOFF_MAX_RESTARTS",
           default: 10000, map: &String.to_integer/1, required: false},
          {:state_handoff_max_seconds, "SPAWN_SUPERVISORS_STATE_HANDOFF_MAX_SECONDS",
           default: 3600, map: &String.to_integer/1, required: false},

          # Internal Nats Protocol
          {:use_internal_nats, "SPAWN_USE_INTERNAL_NATS", default: "false", required: false},
          {:internal_nats_hosts, "SPAWN_INTERNAL_NATS_HOSTS",
           default: "nats://127.0.0.1:4222", required: false},
          {:internal_nats_tls, "SPAWN_INTERNAL_NATS_TLS", default: "false", required: false},
          {:internal_nats_auth, "SPAWN_INTERNAL_NATS_AUTH", default: "false", required: false},
          {:internal_nats_auth_type, "SPAWN_INTERNAL_NATS_AUTH_TYPE",
           default: "simple", required: false},
          {:internal_nats_auth_user, "SPAWN_INTERNAL_NATS_AUTH_USER",
           default: "admin", required: false},
          {:internal_nats_auth_pass, "SPAWN_INTERNAL_NATS_AUTH_PASS",
           default: "admin", required: false},
          {:internal_nats_auth_jwt, "SPAWN_INTERNAL_NATS_AUTH_JWT", default: "", required: false},
          {:internal_nats_connection_backoff_period, "SPAWN_INTERNAL_NATS_BACKOFF_PERIOD",
           default: 3000, map: &String.to_integer/1, required: false},

          # PubSub
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
           default: "", required: false},
          #
          {:delayed_invokes, "SPAWN_DELAYED_INVOKES", default: "true", required: false},
          {:sync_interval, "SPAWN_CRDT_SYNC_INTERVAL",
           default: 2, map: &String.to_integer/1, required: false},
          {:ship_interval, "SPAWN_CRDT_SHIP_INTERVAL",
           default: 2, map: &String.to_integer/1, required: false},
          {:ship_debounce, "SPAWN_CRDT_SHIP_DEBOUNCE",
           default: 2, map: &String.to_integer/1, required: false},
          {:neighbours_sync_interval, "SPAWN_STATE_HANDOFF_SYNC_INTERVAL",
           default: 60_000, map: &String.to_integer/1, required: false}
        ]
      }
    ]

    config = Vapor.load!(providers)

    Logger.info("[Proxy.Config] Loading configs")

    Enum.each(config, fn {key, value} ->
      value_str = if String.contains?(Atom.to_string(key), "secret"), do: "****", else: value
      Logger.debug("Loading config: [#{key}]:[#{value_str}]")

      if key == :state_handoff_controller_adapter do
        case value do
          "crdt" ->
            Application.put_env(
              :spawn,
              key,
              Spawn.Cluster.StateHandoff.Controllers.CrdtController,
              persistent: true
            )

          _ ->
            Application.put_env(
              :spawn,
              key,
              Spawn.Cluster.StateHandoff.Controllers.PersistentController,
              persistent: true
            )

            backend_adapter = load_lookup_adapter()

            Application.put_env(
              :spawn,
              :state_handoff_controller_persistent_backend,
              backend_adapter,
              persistent: true
            )
        end
      else
        Application.put_env(:spawn, key, value, persistent: true)
      end
    end)

    set_http_client_adapter(config)

    config
  end

  defp set_http_client_adapter(config) do
    case config.proxy_http_client_adapter do
      _finch_only_now ->
        Application.put_env(:tesla, :adapter, {Tesla.Adapter.Finch, [name: SpawnHTTPClient]},
          persistent: true
        )
    end
  end

  defp update_state(state) do
    if state == %{} do
      config = load_system_env()
      {config, config}
    else
      {state, state}
    end
  end
end
