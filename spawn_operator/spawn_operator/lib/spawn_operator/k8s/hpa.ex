defmodule Eigr.FunctionsController.K8S.HPA do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @default_actor_host_function_replicas 1

  @default_autoscaler %{
    "min" => 1,
    "max" => 2,
    "averageCpuUtilizationPercentage" =>  80,
    "averageMemoryUtilizationValue"  =>  "250Mi",
  }

  @impl true
  def manifest(system, ns, name, params), do: gen_autoscaler(system, ns, name, params)

  defp gen_autoscaler(system, ns, name, params) do
    autoscaler = Map.get(params, "autoscaler", @default_autoscaler)
    replicas = Map.get(params, "replicas", @default_actor_host_function_replicas)

    minReplicas = Map.get(autoscaler, "min", replicas)
    maxReplicas = Map.get(autoscaler, "max")

    averageCpuUtilizationPercentage =
      Map.get(autoscaler, "averageCpuUtilizationPercentage")

    averageMemoryUtilizationValue =
      Map.get(autoscaler, "averageMemoryUtilizationValue")

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
