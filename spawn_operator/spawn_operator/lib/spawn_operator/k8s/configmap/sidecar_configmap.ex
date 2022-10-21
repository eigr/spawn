defmodule SpawnOperator.K8s.Configmap.SidecarCM do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(system, ns, name, params), do: gen_configmap(system, ns, name, params)

  defp gen_configmap(system, ns, name, params) do
    port = 9001
    # {:app_name, "PROXY_APP_NAME", default: Config.Name.generate(), required: false},
    # {:http_port, "PROXY_HTTP_PORT",
    #   default: 4000, map: &String.to_integer/1, required: false},
    # {:proxy_cluster_strategy, "PROXY_CLUSTER_STRATEGY", default: "gossip", required: false},
    # {:proxy_headless_service, "PROXY_HEADLESS_SERVICE",
    #   default: "proxy-headless-svc", required: false},
    # {:proxy_cluster_poling_interval, "PROXY_CLUSTER_POLLING",
    #   default: 3_000, map: &String.to_integer/1, required: false},
    # {:proxy_uds_enable, "PROXY_UDS_ENABLED", default: false, required: false},
    # {:proxy_sock_addr, "PROXY_UDS_ADDRESS",
    #   default: "/var/run/spawn.sock", required: false},
    # {:user_function_host, "USER_FUNCTION_HOST", default: "0.0.0.0", required: false},
    # {:user_function_port, "USER_FUNCTION_PORT",
    #   default: 8090, map: &String.to_integer/1, required: false},
    # {:proxy_db_type, "PROXY_DATABASE_TYPE", default: "postgres", required: false},
    # {:proxy_db_name, "PROXY_DATABASE_NAME", default: "eigr-functions-db", required: false},
    # {:proxy_db_username, "PROXY_DATABASE_USERNAME", default: "admin", required: false},
    # {:proxy_db_secret, "PROXY_DATABASE_SECRET", default: "admin", required: false},
    # {:proxy_db_host, "PROXY_DATABASE_HOST", default: "localhost", required: false},
    # {:proxy_db_port, "PROXY_DATABASE_PORT",
    #   default: 5432, map: &String.to_integer/1, required: false}

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{
        "namespace" => ns,
        "name" => "#{name}-sidecar-cm"
      },
      "data" => %{
        "PROXY_APP_NAME" => name,
        "PROXY_CLUSTER_POLLING" => "3000",
        "PROXY_CLUSTER_STRATEGY" => "kubernetes-dns",
        "PROXY_HEADLESS_SERVICE" => "proxy-headless-svc",
        "PROXY_HEARTBEAT_INTERVAL" => "240000",
        "PROXY_HTTP_PORT" => "9001",
        "PROXY_PORT" => "9000",
        "PROXY_ROOT_TEMPLATE_PATH" => "/home/app",
        #        "PROXY_UDS_ADDRESS" => "#{socket_path}",
        #        "PROXY_UDS_MODE" => uds_mode,
        "USER_FUNCTION_HOST" => "127.0.0.1",
        "USER_FUNCTION_PORT" => "#{port}"
      }
    }
  end
end
