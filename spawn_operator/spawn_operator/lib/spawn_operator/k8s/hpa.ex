defmodule SpawnOperator.K8s.HPA do
  @moduledoc false

  import Bonny.Config, only: [conn: 0]

  @behaviour SpawnOperator.K8s.Manifest

  @default_actor_host_function_replicas 1

  @default_autoscaler %{
    "min" => 1,
    "max" => 2,
    "averageCpuUtilizationPercentage" => 80,
    "averageMemoryUtilizationValue" => "250Mi"
  }

  @impl true
  def manifest(system, ns, name, params), do: gen_autoscaler(system, ns, name, params)

  defp gen_autoscaler(system, ns, name, params) do
    autoscaler = Map.get(params, "autoscaler", @default_autoscaler)

    {:ok, result} =
      K8s.Client.list("v1", "nodes")
      |> then(&K8s.Client.run(conn(), &1))

    nodes = Map.get(result, "items")

    autoscaler_max =
      if nodes == 1 do
        2
      else
        nodes
      end

    replicas = Map.get(params, "replicas", @default_actor_host_function_replicas)

    max = if replicas > autoscaler_max, do: replicas, else: autoscaler_max

    maxReplicas = Map.get(autoscaler, "max", max)
    minReplicas = Map.get(autoscaler, "min", @default_actor_host_function_replicas)

    averageCpuUtilizationPercentage = Map.get(autoscaler, "averageCpuUtilizationPercentage")

    averageMemoryUtilizationValue = Map.get(autoscaler, "averageMemoryUtilizationValue")

    %{
      "apiVersion" => "autoscaling/v2",
      "kind" => "HorizontalPodAutoscaler",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
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
                "averageValue" => averageMemoryUtilizationValue
              }
            }
          }
        ]
      }
    }
  end
end
