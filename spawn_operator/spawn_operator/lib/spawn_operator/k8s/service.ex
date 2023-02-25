defmodule SpawnOperator.K8s.Service do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(
        %{
          system: _system,
          namespace: ns,
          name: name,
          params: params,
          labels: _labels,
          annotations: annotations
        } = _resource,
        _opts \\ []
      ) do
    proxy_http_port = String.to_integer(annotations.proxy_http_port)

    default_actor_host_function_ports = [
      %{
        "name" => "proxy-http",
        "protocol" => "TCP",
        "port" => proxy_http_port,
        "targetPort" => proxy_http_port
      }
    ]

    host_params = Map.get(params, "host")
    actor_host_function_ports = Map.get(host_params, "ports", [])

    actor_host_function_ports =
      Enum.map(actor_host_function_ports, fn map ->
        if Map.has_key?(map, "containerPort") do
          port = Map.get(map, "containerPort")
          m = Map.delete(map, "containerPort")
          m = Map.put(m, "port", port)
          Map.put(m, "targetPort", port)
        else
          []
        end
      end)
      |> List.flatten()

    actor_host_function_ports =
      if length(actor_host_function_ports) > 0 do
        (actor_host_function_ports ++
           default_actor_host_function_ports)
        |> Enum.uniq()
      else
        default_actor_host_function_ports
      end

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "spawn-eigr.io/controller.version" =>
            "#{to_string(Application.spec(:spawn_operator, :vsn))}"
        },
        "name" => "#{name}",
        "namespace" => ns
      },
      "spec" => %{
        "selector" => %{"app" => name},
        "ports" => actor_host_function_ports
      }
    }
  end
end
