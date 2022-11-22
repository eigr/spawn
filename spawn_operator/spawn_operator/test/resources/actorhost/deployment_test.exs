defmodule DeploymentTest do
  use ExUnit.Case
  use Bonny.Axn.Test

  alias SpawnOperator.K8s.Deployment

  import SpawnOperator.FactoryTest

  setup do
    simple_host = build_simple_actor_host()
    simple_host_with_ports = build_simple_actor_host_with_ports()
    %{simple_host: simple_host, simple_host_with_ports: simple_host_with_ports}
  end

  describe "manifest/1" do
    test "generate deployment with defaults", ctx do
      %{
        simple_host: simple_host_resource,
        simple_host_with_ports: _simple_host_with_ports_resource
      } = ctx

      assert %{
               "apiVersion" => "apps/v1",
               "kind" => "Deployment",
               "metadata" => %{
                 "labels" => %{
                   "actor-system" => "spawn-system",
                   "app" => "spawn-test"
                 },
                 "name" => "spawn-test",
                 "namespace" => "default"
               },
               "spec" => %{
                 "replicas" => 1,
                 "selector" => %{
                   "matchLabels" => %{
                     "actor-system" => "spawn-system",
                     "app" => "spawn-test"
                   }
                 },
                 "strategy" => %{
                   "rollingUpdate" => %{"maxSurge" => 1, "maxUnavailable" => 1},
                   "type" => "RollingUpdate"
                 },
                 "template" => %{
                   "metadata" => %{
                     "annotations" => %{
                       "prometheus.io/port" => "9001",
                       "prometheus.io/scrape" => "true"
                     },
                     "labels" => %{
                       "actor-system" => "spawn-system",
                       "app" => "spawn-test"
                     }
                   },
                   "spec" => %{
                     "containers" => [
                       %{
                         "env" => [
                           %{
                             "name" => "NAMESPACE",
                             "valueFrom" => %{
                               "fieldRef" => %{"fieldPath" => "metadata.namespace"}
                             }
                           },
                           %{
                             "name" => "POD_IP",
                             "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
                           },
                           %{"name" => "SPAWN_PROXY_PORT", "value" => "9001"},
                           %{"name" => "SPAWN_PROXY_INTERFACE", "value" => "0.0.0.0"}
                         ],
                         "envFrom" => [
                           %{
                             "configMapRef" => %{
                               "name" => "spawn-test-sidecar-cm"
                             }
                           },
                           %{"secretRef" => %{"name" => "spawn-system-secret"}}
                         ],
                         "image" => "docker.io/eigr/spawn-proxy:0.1.0",
                         "livenessProbe" => %{
                           "failureThreshold" => 10,
                           "httpGet" => %{
                             "path" => "/health",
                             "port" => 9001,
                             "scheme" => "HTTP"
                           },
                           "initialDelaySeconds" => 300,
                           "periodSeconds" => 3600,
                           "successThreshold" => 1,
                           "timeoutSeconds" => 1200
                         },
                         "name" => "spawn-sidecar",
                         "ports" => [
                           %{"containerPort" => 9000, "name" => "http"},
                           %{"containerPort" => 9001, "name" => "https"},
                           %{"containerPort" => 4369, "name" => "epmd"}
                         ],
                         "resources" => %{
                           "limits" => %{"memory" => "1024Mi"},
                           "requests" => %{"memory" => "80Mi"}
                         }
                       },
                       %{
                         "env" => [
                           %{
                             "name" => "NAMESPACE",
                             "valueFrom" => %{
                               "fieldRef" => %{"fieldPath" => "metadata.namespace"}
                             }
                           },
                           %{
                             "name" => "POD_IP",
                             "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
                           },
                           %{"name" => "SPAWN_PROXY_PORT", "value" => "9001"},
                           %{"name" => "SPAWN_PROXY_INTERFACE", "value" => "0.0.0.0"}
                         ],
                         "image" => "eigr/spawn-test:latest",
                         "name" => "actor-host-function",
                         "ports" => [
                           %{"containerPort" => 9000, "name" => "proxy-http"},
                           %{"containerPort" => 9001, "name" => "proxy-https"},
                           %{"containerPort" => 4369, "name" => "epmd"}
                         ],
                         "resources" => %{
                           "limits" => %{"memory" => "1024Mi"},
                           "requests" => %{"memory" => "80Mi"}
                         }
                       }
                     ],
                     "terminationGracePeriodSeconds" => 120
                   }
                 }
               }
             } = build_host_deploy(simple_host_resource)
    end
  end

  defp build_host_deploy(resource) do
    SpawnOperator.get_args(resource)
    |> Deployment.manifest()
  end
end
