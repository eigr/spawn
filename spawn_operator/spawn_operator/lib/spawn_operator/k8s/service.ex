defmodule SpawnOperator.K8s.Service do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @default_actor_host_function_ports [
    %{"containerPort" => 9001}
  ]

  @impl true
  def manifest(_system, ns, name, params) do
    host_params = Map.get(params, "host")
    actor_host_function_ports = Map.get(host_params, "ports", [])
    actor_host_function_ports = actor_host_function_ports ++ @default_actor_host_function_ports

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "spawn-eigr.io/controller.version" =>
            "#{to_string(Application.spec(:spawn_operator, :vsn))}"
        },
        "name" => "#{name}-svc",
        "namespace" => ns
      },
      "spec" => %{
        "selector" => %{"app" => name},
        "ports" => actor_host_function_ports
      }
    }
  end
end
