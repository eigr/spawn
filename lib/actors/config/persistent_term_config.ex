if Code.ensure_loaded?(:persistent_term) do
  defmodule Actors.Config.PersistentTermConfig do
    @moduledoc """
    `Config.PersistentTermConfig` Implements the `Config` behavior
    to allow the retrieval of system variables
    that will be included in the system configuration.
    """
    require Logger

    @behaviour Actors.Config

    @application :spawn

    @default_actor_system_name "spawn-system"

    @default_finch_pool_count System.schedulers_online()

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
      {:http_num_acceptors, "150"},
      {:grpc_port, "9980"},
      {:grpc_server_enabled, "true"},
      {:grpc_reflection_enabled, "true"},
      {:grpc_http_transcoding_enabled, "true"},
      # default values are evaluated at runtime.
      {:grpc_compiled_modules_path, :runtime},
      {:grpc_actors_protos_path, :runtime},
      {:grpc_include_protos_path, :runtime},
      {:internal_nats_hosts, "nats://127.0.0.1:4222"},
      {:internal_nats_tls, "false"},
      {:internal_nats_auth, "false"},
      {:internal_nats_auth_type, "simple"},
      {:internal_nats_auth_user, "admin"},
      {:internal_nats_auth_pass, "admin"},
      {:internal_nats_auth_jwt, ""},
      {:internal_nats_connection_backoff_period, "3000"},
      {:logger_level, "debug"},
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
      {:proxy_proto_descriptor_path, "/app/protos/user-function.desc"},
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
      {:proxy_db_port, "3306"},
      {:proxy_db_pool_size, "50"},
      {:proxy_db_type, "mariadb"},
      {:ship_interval, "2"},
      {:ship_debounce, "2"},
      {:sync_interval, "2"},
      {:state_handoff_controller_adapter, "crdt"},
      {:state_handoff_manager_pool_size, "20"},
      {:state_handoff_manager_call_timeout, "60000"},
      {:state_handoff_manager_call_pool_min, "0"},
      {:state_handoff_manager_call_pool_max, "-1"},
      {:state_handoff_max_restarts, "10000"},
      {:state_handoff_max_seconds, "3600"},
      {:user_function_host, "0.0.0.0"},
      {:user_function_port, "8090"},
      {:use_internal_nats, "false"}
    ]

    @pool_percent_factor 40

    @impl true
    def load(), do: load_all_envs()

    @impl true
    def get(key) do
      :persistent_term.get({__MODULE__, key})
    end

    defp load_all_envs() do
      Logger.info("[Proxy.Config] Loading configs")

      Enum.each(@all_envs, fn {key, _value} = tuple ->
        env_value = load_env(tuple)

        value_str =
          if String.contains?(Atom.to_string(key), "secret"), do: "****", else: env_value

        Logger.info("Loading config: [#{key}]:[#{value_str}]")
      end)
    end

    defp load_env({:actors_max_restarts, default}) do
      value =
        env("SPAWN_SUPERVISORS_ACTORS_MAX_RESTARTS", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :actors_max_restarts}, value)

      value
    end

    defp load_env({:actors_max_seconds, default}) do
      value =
        env("SPAWN_SUPERVISORS_ACTORS_MAX_SECONDS", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :actors_max_seconds}, value)

      value
    end

    defp load_env({:actors_global_backpressure_max_demand, default}) do
      value =
        env("ACTORS_GLOBAL_BACKPRESSURE_MAX_DEMAND", default)
        |> String.to_integer()

      value =
        if value == -1 do
          base = 1 + @pool_percent_factor / 100
          proxy_db_pool_size = load_env({:proxy_db_pool_size, "50"})
          max_pool_size = round(proxy_db_pool_size * base)

          max_pool_size = if max_pool_size > 0, do: max_pool_size, else: max_pool_size * -1

          max_pool_size
        else
          value
        end

      :persistent_term.put({__MODULE__, :actors_global_backpressure_max_demand}, value)

      value
    end

    defp load_env({:actors_global_backpressure_min_demand, default}) do
      value =
        env("ACTORS_GLOBAL_BACKPRESSURE_MIN_DEMAND", default)
        |> String.to_integer()

      value =
        if value == -1 do
          max_pool_size = load_env({:actors_global_backpressure_max_demand, "-1"})
          min_pool_size = round(max_pool_size * 0.5)

          min_pool_size = if min_pool_size > 0, do: min_pool_size, else: min_pool_size * -1

          min_pool_size
        else
          value
        end

      :persistent_term.put({__MODULE__, :actors_global_backpressure_min_demand}, value)

      value
    end

    defp load_env({:actors_global_backpressure_enabled, default}) do
      value =
        env("ACTORS_GLOBAL_BACKPRESSURE_ENABLED", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :actors_global_backpressure_enabled}, value)

      value
    end

    defp load_env({:delayed_invokes, default}) do
      value =
        env("SPAWN_DELAYED_INVOKES", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :delayed_invokes}, value)

      value
    end

    defp load_env({:deployment_mode, default}) do
      value = env("PROXY_DEPLOYMENT_MODE", default)
      :persistent_term.put({__MODULE__, :deployment_mode}, value)

      value
    end

    defp load_env({:app_name, default}) do
      value = env("PROXY_APP_NAME", default)
      :persistent_term.put({__MODULE__, :app_name}, value)

      value
    end

    defp load_env({:actor_system_name, default}) do
      value = env("PROXY_ACTOR_SYSTEM_NAME", default)
      :persistent_term.put({__MODULE__, :actor_system_name}, value)

      value
    end

    defp load_env({:http_port, default}) do
      value =
        env("PROXY_HTTP_PORT", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :http_port}, value)

      value
    end

    defp load_env({:grpc_port, default}) do
      value =
        env("PROXY_GRPC_PORT", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :grpc_port}, value)

      value
    end

    defp load_env({:grpc_server_enabled, default}) do
      value =
        env("PROXY_GRPC_SERVER_ENABLED", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :grpc_server_enabled}, value)

      value
    end

    defp load_env({:grpc_reflection_enabled, default}) do
      value =
        env("PROXY_GRPC_REFLECTION_ENABLED", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :grpc_reflection_enabled}, value)

      value
    end

    defp load_env({:grpc_http_transcoding_enabled, default}) do
      value =
        env("PROXY_GRPC_HTTP_TRANSCODING_ENABLED", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :grpc_http_transcoding_enabled}, value)

      value
    end

    defp load_env({:grpc_actors_protos_path, :runtime}) do
      default_value = "#{File.cwd!()}/priv/protos/actors"

      value = env("PROXY_GRPC_ACTORS_PROTOS_PATH", default_value)
      :persistent_term.put({__MODULE__, :grpc_actors_protos_path}, value)

      value
    end

    defp load_env({:grpc_include_protos_path, :runtime}) do
      default_value = "#{File.cwd!()}/priv/protos"

      value = env("PROXY_GRPC_INCLUDE_PROTOS_PATH", default_value)
      :persistent_term.put({__MODULE__, :grpc_include_protos_path}, value)

      value
    end

    defp load_env({:grpc_compiled_modules_path, :runtime}) do
      default_value = if System.get_env("MIX_ENV") == "prod" do
        "#{File.cwd!()}/priv/generated_modules"
      else
        "#{File.cwd!()}/lib/_generated"
      end

      value = env("PROXY_GRPC_COMPILED_MODULES_PATH", default_value)
      :persistent_term.put({__MODULE__, :grpc_compiled_modules_path}, value)

      value
    end

    defp load_env({:http_num_acceptors, default}) do
      value =
        env("PROXY_HTTP_NUM_ACCEPTORS", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :http_num_acceptors}, value)

      value
    end

    defp load_env({:internal_nats_hosts, default}) do
      value = env("SPAWN_INTERNAL_NATS_HOSTS", default)
      :persistent_term.put({__MODULE__, :internal_nats_hosts}, value)

      value
    end

    defp load_env({:internal_nats_tls, default}) do
      value =
        env("SPAWN_INTERNAL_NATS_TLS", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :internal_nats_tls}, value)

      value
    end

    defp load_env({:internal_nats_auth, default}) do
      value =
        env("SPAWN_INTERNAL_NATS_AUTH", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :internal_nats_auth}, value)

      value
    end

    defp load_env({:internal_nats_auth_type, default}) do
      value = env("SPAWN_INTERNAL_NATS_AUTH_TYPE", default)
      :persistent_term.put({__MODULE__, :internal_nats_auth_type}, value)

      value
    end

    defp load_env({:internal_nats_auth_user, default}) do
      value = env("SPAWN_INTERNAL_NATS_AUTH_USER", default)
      :persistent_term.put({__MODULE__, :internal_nats_auth_user}, value)

      value
    end

    defp load_env({:internal_nats_auth_pass, default}) do
      value = env("SPAWN_INTERNAL_NATS_AUTH_PASS", default)
      :persistent_term.put({__MODULE__, :internal_nats_auth_pass}, value)

      value
    end

    defp load_env({:internal_nats_auth_jwt, default}) do
      value = env("SPAWN_INTERNAL_NATS_AUTH_JWT", default)
      :persistent_term.put({__MODULE__, :internal_nats_auth_jwt}, value)

      value
    end

    defp load_env({:internal_nats_connection_backoff_period, default}) do
      value =
        env("SPAWN_INTERNAL_NATS_BACKOFF_PERIOD", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :internal_nats_connection_backoff_period}, value)

      value
    end

    defp load_env({:logger_level, default}) do
      value =
        env("SPAWN_PROXY_LOGGER_LEVEL", default)
        |> String.to_atom()

      :persistent_term.put({__MODULE__, :logger_level}, value)

      value
    end

    defp load_env({:neighbours_sync_interval, default}) do
      value =
        env("SPAWN_STATE_HANDOFF_SYNC_INTERVAL", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :neighbours_sync_interval}, value)

      value
    end

    defp load_env({:node_host_interface, default}) do
      value = env("NODE_IP", default)
      :persistent_term.put({__MODULE__, :node_host_interface}, value)

      value
    end

    defp load_env({:pubsub_adapter, default}) do
      value = env("SPAWN_PUBSUB_ADAPTER", default)
      :persistent_term.put({__MODULE__, :pubsub_adapter}, value)

      value
    end

    defp load_env({:pubsub_adapter_nats_hosts, default}) do
      value = env("SPAWN_PUBSUB_NATS_HOSTS", default)
      :persistent_term.put({__MODULE__, :pubsub_adapter_nats_hosts}, value)

      value
    end

    defp load_env({:pubsub_adapter_nats_tls, default}) do
      value =
        env("SPAWN_PUBSUB_NATS_TLS", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :pubsub_adapter_nats_tls}, value)

      value
    end

    defp load_env({:pubsub_adapter_nats_auth, default}) do
      value = env("SPAWN_PUBSUB_NATS_AUTH", default)
      :persistent_term.put({__MODULE__, :pubsub_adapter_nats_auth}, value)

      value
    end

    defp load_env({:pubsub_adapter_nats_auth_type, default}) do
      value = env("SPAWN_PUBSUB_NATS_AUTH_TYPE", default)
      :persistent_term.put({__MODULE__, :pubsub_adapter_nats_auth_type}, value)

      value
    end

    defp load_env({:pubsub_adapter_nats_auth_user, default}) do
      value = env("SPAWN_PUBSUB_NATS_AUTH_USER", default)
      :persistent_term.put({__MODULE__, :pubsub_adapter_nats_auth_user}, value)

      value
    end

    defp load_env({:pubsub_adapter_nats_auth_pass, default}) do
      value = env("SPAWN_PUBSUB_NATS_AUTH_PASS", default)
      :persistent_term.put({__MODULE__, :pubsub_adapter_nats_auth_pass}, value)

      value
    end

    defp load_env({:pubsub_adapter_nats_auth_jwt, default}) do
      value = env("SPAWN_PUBSUB_NATS_AUTH_JWT", default)
      :persistent_term.put({__MODULE__, :pubsub_adapter_nats_auth_jwt}, value)

      value
    end

    defp load_env({:proxy_http_client_adapter, default}) do
      value = env("PROXY_HTTP_CLIENT_ADAPTER", default)
      :persistent_term.put({__MODULE__, :proxy_http_client_adapter}, value)

      value
    end

    defp load_env({:proxy_http_client_adapter_pool_schedulers, default}) do
      value =
        env("PROXY_HTTP_CLIENT_ADAPTER_POOL_SCHEDULERS", default)
        |> String.to_integer()

      value =
        if value == 0,
          do: @default_finch_pool_count,
          else: value

      :persistent_term.put({__MODULE__, :proxy_http_client_adapter_pool_schedulers}, value)

      value
    end

    defp load_env({:proxy_http_client_adapter_pool_size, default}) do
      value =
        env("PROXY_HTTP_CLIENT_ADAPTER_POOL_SIZE", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :proxy_http_client_adapter_pool_size}, value)

      value
    end

    defp load_env({:proxy_http_client_adapter_pool_max_idle_timeout, default}) do
      value =
        env("PROXY_HTTP_CLIENT_ADAPTER_POOL_MAX_IDLE_TIMEOUT", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :proxy_http_client_adapter_pool_max_idle_timeout}, value)

      value
    end

    defp load_env({:proxy_proto_descriptor_path, default}) do
      value = env("PROXY_PROTO_DESCRIPTOR_PATH", default)

      :persistent_term.put({__MODULE__, :proxy_proto_descriptor_path}, value)

      value
    end

    defp load_env({:proxy_cluster_strategy, default}) do
      value = env("PROXY_CLUSTER_STRATEGY", default)
      :persistent_term.put({__MODULE__, :proxy_cluster_strategy}, value)

      value
    end

    defp load_env({:proxy_headless_service, default}) do
      value = env("PROXY_HEADLESS_SERVICE", default)
      :persistent_term.put({__MODULE__, :proxy_headless_service}, value)

      value
    end

    defp load_env({:proxy_cluster_polling_interval, default}) do
      value =
        env("PROXY_CLUSTER_POLLING", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :proxy_cluster_polling_interval}, value)

      value
    end

    defp load_env({:proxy_cluster_gossip_broadcast_only, default}) do
      value =
        env("PROXY_CLUSTER_GOSSIP_BROADCAST_ONLY", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :proxy_cluster_gossip_broadcast_only}, value)

      value
    end

    defp load_env({:proxy_cluster_gossip_reuseaddr_address, default}) do
      value =
        env("PROXY_CLUSTER_GOSSIP_REUSE_ADDRESS", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :proxy_cluster_gossip_reuseaddr_address}, value)

      value
    end

    defp load_env({:proxy_cluster_gossip_multicast_address, default}) do
      value = env("PROXY_CLUSTER_GOSSIP_MULTICAST_ADDRESS", default)
      :persistent_term.put({__MODULE__, :proxy_cluster_gossip_multicast_address}, value)

      value
    end

    defp load_env({:proxy_uds_enable, default}) do
      value =
        env("PROXY_UDS_ENABLED", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :proxy_uds_enable}, value)

      value
    end

    defp load_env({:proxy_sock_addr, default}) do
      value = env("PROXY_UDS_ADDRESS", default)
      :persistent_term.put({__MODULE__, :proxy_sock_addr}, value)

      value
    end

    defp load_env({:proxy_host_interface, default}) do
      value = env("PROXY_HOST_INTERFACE", default)
      :persistent_term.put({__MODULE__, :proxy_host_interface}, value)

      value
    end

    defp load_env({:proxy_disable_metrics, default}) do
      value =
        env("SPAWN_DISABLE_METRICS", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :proxy_disable_metrics}, value)

      value
    end

    defp load_env({:proxy_console_metrics, default}) do
      value =
        env("SPAWN_CONSOLE_METRICS", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :proxy_console_metrics}, value)

      value
    end

    defp load_env({:proxy_db_name, default}) do
      value = env("PROXY_DATABASE_NAME", default)
      :persistent_term.put({__MODULE__, :proxy_db_name}, value)

      value
    end

    defp load_env({:proxy_db_username, default}) do
      value = env("PROXY_DATABASE_USERNAME", default)
      :persistent_term.put({__MODULE__, :proxy_db_username}, value)

      value
    end

    defp load_env({:proxy_db_secret, default}) do
      value = env("PROXY_DATABASE_SECRET", default)
      :persistent_term.put({__MODULE__, :proxy_db_secret}, value)

      value
    end

    defp load_env({:proxy_db_host, default}) do
      value = env("PROXY_DATABASE_HOST", default)
      :persistent_term.put({__MODULE__, :proxy_db_host}, value)

      value
    end

    defp load_env({:proxy_db_port, default}) do
      default =
        if Code.ensure_loaded?(Statestores.Supervisor) do
          Statestores.Util.get_default_database_port()
        else
          default
        end

      value =
        env("PROXY_DATABASE_PORT", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :proxy_db_port}, value)

      value
    end

    defp load_env({:proxy_db_type, default}) do
      default =
        if Code.ensure_loaded?(Statestores.Supervisor) do
          Statestores.Util.get_default_database_type()
        else
          default
        end

      value = env("PROXY_DATABASE_TYPE", default)

      :persistent_term.put({__MODULE__, :proxy_db_type}, value)

      value
    end

    defp load_env({:proxy_db_pool_size, default}) do
      value =
        env("PROXY_DATABASE_POOL_SIZE", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :proxy_db_pool_size}, value)

      value
    end

    defp load_env({:ship_interval, default}) do
      value =
        env("SPAWN_CRDT_SHIP_INTERVAL", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :ship_interval}, value)

      value
    end

    defp load_env({:ship_debounce, default}) do
      value =
        env("SPAWN_CRDT_SHIP_DEBOUNCE", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :ship_debounce}, value)

      value
    end

    defp load_env({:sync_interval, default}) do
      value =
        env("SPAWN_CRDT_SHIP_DEBOUNCE", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :sync_interval}, value)

      value
    end

    defp load_env({:state_handoff_controller_adapter, default}) do
      value_str = env("SPAWN_SUPERVISORS_STATE_HANDOFF_CONTROLLER", default)

      case value_str do
        "crdt" ->
          Application.put_env(
            :spawn,
            :state_handoff_controller_adapter,
            Spawn.Cluster.StateHandoff.Controllers.CrdtController,
            persistent: true
          )

        "nats" ->
          Application.put_env(
            :spawn,
            :state_handoff_controller_adapter,
            Spawn.Cluster.StateHandoff.Controllers.NatsKvController,
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

      :persistent_term.put({__MODULE__, :state_handoff_controller_adapter}, value_str)

      value_str
    end

    defp load_env({:state_handoff_manager_pool_size, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_POOL_SIZE", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_manager_pool_size}, value)

      value
    end

    defp load_env({:state_handoff_manager_call_timeout, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_CALL_TIMEOUT", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_manager_call_timeout}, value)

      value
    end

    defp load_env({:state_handoff_manager_call_pool_min, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_CALL_POOL_MIN", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_manager_call_pool_min}, value)

      value
    end

    defp load_env({:state_handoff_manager_call_pool_max, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MANAGER_CALL_POOL_MAX", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_manager_call_pool_max}, value)

      value
    end

    defp load_env({:state_handoff_max_restarts, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MAX_RESTARTS", default)
        |> String.to_integer()

      value = if value < 0, do: default, else: value

      :persistent_term.put({__MODULE__, :state_handoff_max_restarts}, value)

      value
    end

    defp load_env({:state_handoff_max_seconds, default}) do
      value =
        env("SPAWN_SUPERVISORS_STATE_HANDOFF_MAX_SECONDS", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :state_handoff_max_seconds}, value)

      value
    end

    defp load_env({:user_function_host, default}) do
      value = env("USER_FUNCTION_HOST", default)
      :persistent_term.put({__MODULE__, :user_function_host}, value)

      value
    end

    defp load_env({:user_function_port, default}) do
      value =
        env("USER_FUNCTION_PORT", default)
        |> String.to_integer()

      :persistent_term.put({__MODULE__, :user_function_port}, value)

      value
    end

    defp load_env({:use_internal_nats, default}) do
      value =
        env("SPAWN_USE_INTERNAL_NATS", default)
        |> to_bool()

      :persistent_term.put({__MODULE__, :use_internal_nats}, value)

      value
    end

    defp load_env({env_key, default}) when is_atom(env_key) do
      key_str = Atom.to_string(env_key) |> String.upcase()
      env(key_str, default)
    end

    defp env(key, default)

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

    defp to_bool("false"), do: false
    defp to_bool("true"), do: true
    defp to_bool(_), do: false
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
