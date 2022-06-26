defmodule Operator.K8S.HeadlessService do
  @behaviour Operator.K8S.Manifest

  @impl true
  def manifest(ns, _name, _params),
    do: %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "svc-cluster-name" => "svc-proxy",
          "functions.eigr.io/controller.version" =>
            "#{to_string(Application.spec(:eigr_functions_controller, :vsn))}"
        },
        "name" => "proxy-headless-svc",
        "namespace" => ns
      },
      "spec" => %{
        "clusterIP" => "None",
        "selector" => %{"cluster-name" => "proxy"},
        "ports" => [
          %{"port" => 4369, "name" => "epmd"}
        ]
      }
    }
end
