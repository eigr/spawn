defmodule Operator.K8S.NodePort do
  @behaviour Operator.K8S.Manifest

  @impl true
  def manifest(ns, name, params) do
    nodeport = params["expose"]["nodePort"]

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "functions.eigr.io/controller.version" =>
            "#{to_string(Application.spec(:eigr_functions_controller, :vsn))}",
          "functions.eigr.io/wormhole.gate.earth.status" => "open"
        },
        "name" => "#{name}-nodeport",
        "namespace" => ns
      },
      "spec" => %{
        "ports" => [
          %{
            "port" => nodeport["port"],
            "targetPort" => nodeport["targetPort"],
            "nodePort" => nodeport["nodePort"],
            "protocol" => "TCP"
          }
        ],
        "selector" => %{
          "app" => name
        },
        "type" => "NodePort"
      }
    }
  end
end
