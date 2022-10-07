defmodule Operator.K8S.Resources.HPA do
  @behaviour Operator.K8S.Manifest

  @impl true
  def manifest(ns, name, params), do: gen_autoscaler(ns, name, params)

  defp gen_autoscaler(ns, name, params) do
    strategy = Map.get(params, "autoscaler") |> Map.get("strategy")
    minReplicas = Map.get(params, "autoscaler") |> Map.get("minReplicas")
    maxReplicas = Map.get(params, "autoscaler") |> Map.get("maxReplicas")

    averageCpuUtilizationPercentage =
      Map.get(params, "autoscaler") |> Map.get("averageCpuUtilizationPercentage")

    averageMemoryUtilizationValue =
      Map.get(params, "autoscaler") |> Map.get("averageMemoryUtilizationValue")

    %{
      "apiVersion" => "autoscaling/v2beta2",
      "kind" => "HorizontalPodAutoscaler",
      "metadata" => %{
        "name" => "#{name}-#{strategy}-autoscaler",
        "namespace" => ns
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
