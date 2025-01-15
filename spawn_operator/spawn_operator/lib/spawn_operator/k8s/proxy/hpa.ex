defmodule SpawnOperator.K8s.Proxy.HPA do
  @moduledoc false

  import Bonny.Config, only: [conn: 0]

  @behaviour SpawnOperator.K8s.Manifest

  @default_actor_host_function_replicas 1

  @default_autoscaler %{}

  @default_average_cpu_utilization_percentage 700

  @default_average_memory_utilization_value 200

  @impl true
  def manifest(resource, _opts \\ []), do: gen_autoscaler(resource)

  defp gen_autoscaler(
         %{
           system: system,
           namespace: ns,
           name: name,
           params: params,
           labels: _labels,
           annotations: _annotations
         } = _resource
       ) do
    autoscaler = Map.get(params, "autoscaler", @default_autoscaler)

    {:ok, result} =
      K8s.Client.list("v1", "nodes")
      |> then(&K8s.Client.run(conn(), &1))

    nodes = Map.get(result, "items")

    autoscaler_max = length(nodes) * 2

    replicas = Map.get(params, "replicas", @default_actor_host_function_replicas)

    max = if replicas > autoscaler_max, do: replicas, else: autoscaler_max

    maxReplicas = Map.get(autoscaler, "max", max)
    minReplicas = Map.get(autoscaler, "min", @default_actor_host_function_replicas)

    averageCpuUtilizationPercentage =
      Map.get(
        autoscaler,
        "averageCpuUtilizationPercentage",
        @default_average_cpu_utilization_percentage
      )

    averageMemoryUtilizationValue =
      Map.get(
        autoscaler,
        "averageMemoryUtilizationValue",
        @default_average_memory_utilization_value
      )

    %{
      "apiVersion" => "autoscaling/v2",
      "kind" => "HorizontalPodAutoscaler",
      "metadata" => %{
        "name" => name,
        "namespace" => system,
        "labels" => %{"app" => name, "actor-system" => system}
      },
      "spec" => %{
        "scaleTargetRef" => %{
          "apiVersion" => "apps/v1",
          "kind" => "Deployment",
          "name" => "#{name}"
        },
        "minReplicas" => minReplicas,
        "maxReplicas" => maxReplicas,
        "metrics" => [
          %{
            "type" => "Resource",
            "resource" => %{
              "name" => "cpu",
              "target" => %{
                "type" => "Utilization",
                "averageUtilization" => averageCpuUtilizationPercentage
              }
            }
          },
          %{
            "type" => "Resource",
            "resource" => %{
              "name" => "memory",
              "target" => %{
                "type" => "AverageValue",
                "averageUtilization" => averageMemoryUtilizationValue
              }
            }
          }
        ]
      }
    }
  end
end
