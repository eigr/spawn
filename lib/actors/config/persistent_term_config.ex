if Code.ensure_loaded?(:persistent_term) do
  defmodule Actors.Config.PersistentTermConfig do
    @behaviour Actors.Config

    @application :spawn
    @default_actor_system_name "spawn-system"

    @all_envs [
      {:actor_system_name, @default_actor_system_name},
      {:actors_max_restarts, "10000"},
      {:actors_max_seconds, "3600"},
      {:actors_global_backpressure_max_demand, "-1"},
      {:actors_global_backpressure_min_demand, "-1"},
      {:actors_global_backpressure_enabled, "true"},
      {:app_name, Config.Name.generate()},
      {:delayed_invokes, "true"},
      {:deployment_mode, "sidecar"},
      {:http_port, "9001"},
      {:internal_nats_hosts, "nats://127.0.0.1:4222"},
      {:internal_nats_tls, "false"},
      {:internal_nats_auth, "false"},
      {:internal_nats_auth_type, "simple"},
      {:internal_nats_auth_user, "admin"},
      {:internal_nats_auth_pass, "admin"},
      {:internal_nats_auth_jwt, ""},
      {:internal_nats_connection_backoff_period, "3000"},
      {:neighbours_sync_interval, "60000"},
      {:node_host_interface, "0.0.0.0"},
      {:pubsub_adapter, "native"},
      {:pubsub_adapter_nats_hosts, "nats://127.0.0.1:4222"},
      {:pubsub_adapter_nats_tls, "false"},
      {:pubsub_adapter_nats_auth, "false"},
      {:pubsub_adapter_nats_auth_type, "simple"},
      {:pubsub_adapter_nats_auth_user, "admin"},
      {:pubsub_adapter_nats_auth_pass, "admin"},
      {:pubsub_adapter_nats_auth_jwt, ""},
      {:proxy_http_client_adapter, "finch"},
      {:proxy_http_client_adapter_pool_schedulers, "0"},
      {:proxy_http_client_adapter_pool_size, "30"},
      {:proxy_http_client_adapter_pool_max_idle_timeout, "1000"},
      {:proxy_cluster_strategy, "gossip"},
      {:proxy_headless_service, "proxy-headless"},
      {:proxy_cluster_polling_interval, "3000"},
      {:proxy_cluster_gossip_broadcast_only, "true"},
      {:proxy_cluster_gossip_reuseaddr_address, "true"},
      {:proxy_cluster_gossip_multicast_address, "255.255.255.255"},
      {:proxy_uds_enable, "false"},
      {:proxy_sock_addr, "/var/run/spawn.sock"},
      {:proxy_host_interface, "0.0.0.0"},
      {:proxy_disable_metrics, "false"},
      {:proxy_console_metrics, "false"},
      {:proxy_db_name, "eigr-functions-db"},
      {:proxy_db_username, "admin"},
      {:proxy_db_secret, "admin"},
      {:proxy_db_host, "localhost"},
      {:proxy_db_pool_size, "50"},
      {:ship_interval, "2"},
      {:ship_debounce, "2"},
      {:state_handoff_controller_adapter, "crdt"},
      {:state_handoff_manager_pool_size, "20"},
      {:state_handoff_manager_call_timeout, "60000"},
      {:state_handoff_manager_call_pool_min, "0"},
      {:state_handoff_manager_call_pool_max, "-1"},
      {:state_handoff_max_restarts, "-1"},
      {:state_handoff_max_seconds, "3600"},
      {:user_function_host, "0.0.0.0"},
      {:user_function_port, "8090"},
      {:use_internal_nats, "false"}
    ]

    @impl true
    def load(_mod), do: load_all_envs()

    @impl true
    def get(mod, key) do
      :persistent_term.get({mod, key})
    end

    defp load_all_envs(), do: Enum.each(@all_envs, &load_env/1)

    defp load_env({:app_name, default}) do
      value = env("PROXY_APP_NAME", default)
      :persistent_term.put({__MODULE__, :app_name}, value)
    end

    defp load_env({:actor_system_name, default}) do
      value = env("PROXY_ACTOR_SYSTEM_NAME", default)
      :persistent_term.put({__MODULE__, :actor_system_name}, value)
    end

    defp load_env({:http_port, default}) do
      value =
        env("PROXY_HTTP_PORT", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :http_port}, value)
    end

    defp load_env({:proxy_http_client_adapter, default}) do
      value = env("PROXY_HTTP_CLIENT_ADAPTER", default)
      :persistent_term.put({__MODULE__, :proxy_http_client_adapter}, value)
    end

    defp load_env({:proxy_http_client_adapter_pool_schedulers, default}) do
      value =
        env("PROXY_HTTP_CLIENT_ADAPTER_POOL_SCHEDULERS", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :proxy_http_client_adapter_pool_schedulers}, value)
    end

    defp load_env({:proxy_http_client_adapter_pool_size, default}) do
      value =
        env("PROXY_HTTP_CLIENT_ADAPTER_POOL_SIZE", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :proxy_http_client_adapter_pool_size}, value)
    end

    defp load_env({:proxy_http_client_adapter_pool_max_idle_timeout, default}) do
      value =
        env("PROXY_HTTP_CLIENT_ADAPTER_POOL_MAX_IDLE_TIMEOUT", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :proxy_http_client_adapter_pool_max_idle_timeout}, value)
    end

    defp load_env({:proxy_cluster_strategy, default}) do
      value = env("PROXY_CLUSTER_STRATEGY", default)
      :persistent_term.put({__MODULE__, :proxy_cluster_strategy}, value)
    end

    defp load_env({:proxy_headless_service, default}) do
      value = env("PROXY_HEADLESS_SERVICE", default)
      :persistent_term.put({__MODULE__, :proxy_headless_service}, value)
    end

    defp load_env({:proxy_cluster_polling_interval, default}) do
      value =
        env("PROXY_CLUSTER_POLLING", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :proxy_cluster_polling_interval}, value)
    end

    defp load_env({:proxy_cluster_gossip_broadcast_only, default}) do
      value =
        env("PROXY_CLUSTER_GOSSIP_BROADCAST_ONLY", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :proxy_cluster_gossip_broadcast_only}, value)
    end

    defp load_env({:proxy_cluster_gossip_reuseaddr_address, default}) do
      value =
        env("PROXY_CLUSTER_GOSSIP_REUSE_ADDRESS", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :proxy_cluster_gossip_reuseaddr_address}, value)
    end

    defp load_env({:proxy_cluster_gossip_multicast_address, default}) do
      value = env("PROXY_CLUSTER_GOSSIP_MULTICAST_ADDRESS", default)
      :persistent_term.put({__MODULE__, :proxy_cluster_gossip_multicast_address}, value)
    end

    defp load_env({:proxy_uds_enable, default}) do
      value =
        env("PROXY_UDS_ENABLED", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :proxy_uds_enable}, value)
    end

    defp load_env({:proxy_sock_addr, default}) do
      value = env("PROXY_UDS_ADDRESS", default)
      :persistent_term.put({__MODULE__, :proxy_sock_addr}, value)
    end

    defp load_env({:proxy_host_interface, default}) do
      value = env("PROXY_HOST_INTERFACE", default)
      :persistent_term.put({__MODULE__, :proxy_host_interface}, value)
    end

    defp load_env({:proxy_disable_metrics, default}) do
      value =
        env("SPAWN_DISABLE_METRICS", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :proxy_disable_metrics}, value)
    end

    defp load_env({:proxy_console_metrics, default}) do
      value =
        env("SPAWN_CONSOLE_METRICS", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :proxy_console_metrics}, value)
    end

    defp load_env({:proxy_db_name, default}) do
      value = env("PROXY_DATABASE_NAME", default)
      :persistent_term.put({__MODULE__, :proxy_db_name}, value)
    end

    defp load_env({:proxy_db_username, default}) do
      value = env("PROXY_DATABASE_USERNAME", default)
      :persistent_term.put({__MODULE__, :proxy_db_username}, value)
    end

    defp load_env({:proxy_db_secret, default}) do
      value = env("PROXY_DATABASE_SECRET", default)
      :persistent_term.put({__MODULE__, :proxy_db_secret}, value)
    end

    defp load_env({:proxy_db_host, default}) do
      value = env("PROXY_DATABASE_HOST", default)
      :persistent_term.put({__MODULE__, :proxy_db_host}, value)
    end

    defp load_env({:proxy_db_pool_size, default}) do
      value =
        env("PROXY_DATABASE_POOL_SIZE", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :proxy_db_pool_size}, value)
    end

    defp load_env({:ship_interval, default}) do
      value =
        env("SPAWN_CRDT_SHIP_INTERVAL", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :ship_interval}, value)
    end

    defp load_env({:ship_debounce, default}) do
      value =
        env("SPAWN_CRDT_SHIP_DEBOUNCE", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :ship_debounce}, value)
    end

    defp load_env({:state_handoff_controller_adapter, default}) do
      value = env("SPAWN_SUPERVISORS_STATE_HANDOFF_CONTROLLER", default)

      value =
        case value do
          "crdt" ->
            Application.put_env(
              :spawn,
              :state_handoff_controller_adapter,
              Spawn.Cluster.StateHandoff.Controllers.CrdtController,
              persistent: true
            )

          _ ->
            if Code.ensure_loaded?(Statestores.Supervisor) do
              Application.put_env(
                :spawn,
                :state_handoff_controller_adapter,
                Spawn.Cluster.StateHandoff.Controllers.PersistentController,
                persistent: true
              )

              backend_adapter = Statestores.Util.load_lookup_adapter()

              Application.put_env(
                :spawn,
                :state_handoff_controller_persistent_backend,
                backend_adapter,
                persistent: true
              )
            else
              Application.put_env(
                :spawn,
                :state_handoff_controller_adapter,
                Spawn.Cluster.StateHandoff.Controllers.CrdtController,
                persistent: true
              )
            end
        end

      :persistent_term.put({__MODULE__, :state_handoff_controller_adapter}, value)
    end

    defp load_env({:state_handoff_manager_pool_size, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_POOL_SIZE", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_manager_pool_size}, value)
    end

    defp load_env({:state_handoff_manager_call_timeout, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_CALL_TIMEOUT", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_manager_call_timeout}, value)
    end

    defp load_env({:state_handoff_manager_call_pool_min, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_CALL_POOL_MIN", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_manager_call_pool_min}, value)
    end

    defp load_env({:state_handoff_manager_call_pool_max, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_CALL_POOL_MAX", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_manager_call_pool_max}, value)
    end

    defp load_env({:state_handoff_max_restarts, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MAX_RESTARTS", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_max_restarts}, value)
    end

    defp load_env({:state_handoff_max_seconds, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MAX_SECONDS", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_max_seconds}, value)
    end

    defp load_env({:user_function_host, default}) do
      value = env("USER_FUNCTION_HOST", default)
      :persistent_term.put({__MODULE__, :user_function_host}, value)
    end

    defp load_env({:user_function_port, default}) do
      value =
        env("USER_FUNCTION_PORT", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :user_function_port}, value)
    end

    defp load_env({:use_internal_nats, default}) do
      value =
        env("SPAWN_USE_INTERNAL_NATS", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :use_internal_nats}, value)
    end

    defp load_env({env_key, default}) when is_atom(env_key) do
      key_str = Atom.to_string(env_key) |> String.upcase()
      env(key_str, default)
    end

    defp env(key, default \\ nil)

    defp env(key, default) when is_binary(key) do
      case System.get_env(key, default) do
        nil ->
          default

        "" ->
          default

        value ->
          value
      end
    end

    defp env(key, default) when is_atom(key) do
      case Application.get_env(@application, key) do
        nil ->
          default

        "" ->
          default

        value ->
          value
      end
    end

    def to_bool("false"), do: false
    def to_bool("true"), do: true
    def to_bool(_), do: false
  end
else
  defmodule Actors.Config.PersistentTermConfig do
    @moduledoc false

    @error "PersistentTermConfig module can't be used without OTP >= 21.2"

    @behaviour Actors.Config

    @impl true
    def load(_mod), do: raise(@error)

    @impl true
    def get(_mod, _key), do: raise(@error)
  end
end
