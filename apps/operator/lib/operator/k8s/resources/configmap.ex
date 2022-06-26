defmodule Operator.K8S.Resources.ConfigMap do
  @behaviour Operator.K8S.Manifest

  @impl true
  def manifest(ns, name, params), do: gen_configmap(ns, name, params)

  defp gen_configmap(ns, name, params) do
    port_bindings = params["portBindings"]
    port = port_bindings["port"]
    socket_path = port_bindings["socketPath"]

    uds_mode =
      port_bindings["type"]
      |> case do
        "grpc" -> "false"
        "uds" -> "true"
        _ -> "false"
      end

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{
        "labels" => %{
          "functions.eigr.io/controller.version" =>
            "#{to_string(Application.spec(:eigr_functions_controller, :vsn))}"
        },
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
        "PROXY_UDS_ADDRESS" => "#{socket_path}",
        "PROXY_UDS_MODE" => uds_mode,
        "USER_FUNCTION_HOST" => "127.0.0.1",
        "USER_FUNCTION_PORT" => "#{port}"
      }
    }
  end
end
