defmodule SpawnOperator.K8s.ConfigMap.SidecarCM do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(resource, _opts \\ []), do: gen_configmap(resource)

  defp gen_configmap(
         %{
           system: _system,
           namespace: ns,
           name: name,
           params: _params,
           labels: _labels,
           annotations: _annotations
         } = _resource
       ) do
    port = 9001

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
        "PROXY_HOST_INTERFACE" => "http",
        #        "PROXY_UDS_ADDRESS" => "#{socket_path}",
        #        "PROXY_UDS_MODE" => uds_mode,
        "USER_FUNCTION_HOST" => "127.0.0.1",
        "USER_FUNCTION_PORT" => "#{port}"
      }
    }
  end
end
