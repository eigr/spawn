defmodule SpawnOperator.K8s.Deployment do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @default_actor_host_function_env [
    %{
      "name" => "SPAWN_PROXY_PORT",
      "value" => "9001"
    },
    %{
      "name" => "SPAWN_PROXY_INTERFACE",
      "value" => "127.0.0.1"
    }
  ]

  @default_actor_host_function_ports [
    %{"containerPort" => 3000}
  ]

  @default_actor_host_function_replicas 1

  @default_actor_host_function_resources %{
    "limits" => %{
      "memory" => "1024Mi"
    },
    "requests" => %{
      "memory" => "70Mi"
    }
  }

  @impl true
  def manifest(system, ns, name, params), do: gen_deployment(system, ns, name, params)

  defp gen_deployment(system, ns, name, params) do
    host_params = Map.get(params, "host")
    sidecar_params = Map.get(params, "sidecar", %{})

    # TODO: How to treat it? Autoscaling or user defined number of replicas?
    replicas = Map.get(params, "replicas", @default_actor_host_function_replicas)

    actor_host_function_image = Map.get(host_params, "image")

    actor_host_function_envs = Map.get(host_params, "env", []) ++ @default_actor_host_function_env

    actor_host_function_ports = Map.get(host_params, "ports", @default_actor_host_function_ports)

    actor_host_function_resources =
      Map.get(host_params, "resources", @default_actor_host_function_resources)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "labels" => %{"app" => name, "actor-system" => system}
      },
      "spec" => %{
        "replicas" => replicas,
        "selector" => %{
          "matchLabels" => %{"app" => name, "actor-system" => system}
        },
        "strategy" => %{
          "type" => "RollingUpdate",
          "rollingUpdate" => %{
            "maxSurge" => 1,
            "maxUnavailable" => 1
          }
        },
        "template" => %{
          "metadata" => %{
            "annotations" => %{
              "prometheus.io/port" => "9001",
              "prometheus.io/scrape" => "true"
            },
            "labels" => %{
              "app" => name,
              "actor-system" => system
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "name" => "spawn-sidecar",
                "image" => "#{resolve_proxy_image()}",
                "env" => [
                  %{
                    "name" => "PROXY_POD_IP",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
                  }
                ],
                "ports" => [
                  %{"containerPort" => 9000},
                  %{"containerPort" => 9001},
                  %{"containerPort" => 4369}
                ],
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
                "resources" => %{
                  "limits" => %{
                    "memory" => "1024Mi"
                  },
                  "requests" => %{
                    "memory" => "70Mi"
                  }
                },
                "envFrom" => [
                  %{
                    "configMapRef" => %{
                      "name" => "#{name}-sidecar-cm"
                    }
                  },
                  %{
                    "configMapRef" => %{
                      "name" => "#{system}-cm"
                    }
                  }
                ]
              },
              %{
                "name" => "actor-host-function",
                "image" => actor_host_function_image,
                "env" => actor_host_function_envs,
                "ports" => actor_host_function_ports,
                "resources" => actor_host_function_resources
              }
            ],
            "terminationGracePeriodSeconds" => 120
          }
        }
      }
    }
  end

  defp resolve_proxy_image(),
    do:
      Application.get_env(
        :spawn_operator,
        :proxy_image,
        "docker.io/eigr/spawn-proxy:0.1.0"
      )
end
