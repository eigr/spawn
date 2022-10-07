defmodule Operator.K8S.Resources.LoadBalancer do
  @behaviour Operator.K8S.Manifest

  @impl true
  def manifest(ns, name, params) do
    loadBalancer = params["expose"]["loadBalancer"]

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "functions.eigr.io/controller.version" =>
            "#{to_string(Application.spec(:eigr_functions_controller, :vsn))}",
          "functions.eigr.io/wormhole.gate.earth.status" => "open"
        },
        "name" => "#{name}-loadbalancer",
        "namespace" => ns
      },
      "spec" => %{
        "selector" => %{
          "app" => name
        },
        "ports" => [
          %{
            "protocol" => "TCP",
            "port" => loadBalancer["port"],
            "targetPort" => loadBalancer["targetPort"]
          }
        ],
        "type" => "LoadBalancer"
      }
    }
  end
end
