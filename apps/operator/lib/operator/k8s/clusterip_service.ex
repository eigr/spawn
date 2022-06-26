defmodule Operator.K8S.ClusterIPService do
  @behaviour Eigr.FunctionsController.K8S.Manifest

  @http_port 9001
  @proxy_port 9000

  @impl true
  def manifest(ns, name, _params) do
    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "spawn.eigr.io/controller.version" =>
            "#{to_string(Application.spec(:eigr_functions_controller, :vsn))}"
        },
        "name" => "#{name}-svc",
        "namespace" => ns
      },
      "spec" => %{
        "type" => "ClusterIP",
        "selector" => %{"app" => name},
        "ports" => [
          %{"name" => "proxy", "port" => @proxy_port, "targetPort" => @proxy_port},
          %{"name" => "http", "port" => @http_port, "targetPort" => @http_port}
        ]
      }
    }
  end
end
