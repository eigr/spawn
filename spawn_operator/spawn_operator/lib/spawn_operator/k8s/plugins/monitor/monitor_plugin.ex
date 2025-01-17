defmodule SpawnOperator.K8s.Plugins.Monitor do
  @moduledoc false
  @behaviour SpawnOperator.K8s.Plugins

  @default_certs_volume [
    %{
      "name" => "certs",
      "secret" => %{"secretName" => "tls-certs", "optional" => true}
    }
  ]

  @default_monitor_envs [
    %{
      "name" => "RELEASE_NAME",
      "value" => "monitor"
    },
    %{
      "name" => "NAMESPACE",
      "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
    },
    %{
      "name" => "POD_NAME",
      "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
    },
    %{
      "name" => "POD_NAMESPACE",
      "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
    },
    %{
      "name" => "POD_IP",
      "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
    },
    %{
      "name" => "RELEASE_DISTRIBUTION",
      "value" => "name"
    },
    %{
      "name" => "RELEASE_NODE",
      "value" => "$(RELEASE_NAME)@$(POD_IP)"
    }
  ]

  @default_monitor_image "gcr.io/eigr/spawn-monitor:2.0.0-RC4"

  @default_monitor_resources [
    %{
      "requests" => %{
        "cpu" => "100m",
        "memory" => "80Mi",
        "ephemeral-storage" => "1M"
      }
    }
  ]

  @impl true
  def manifest(
        %{
          system: system,
          namespace: ns,
          name: name,
          params: params,
          labels: _labels,
          annotations: annotations
        } = _resource,
        opts
      ) do
    manifests = [
      create_service(system, ns, name),
      create_deployment(system, ns, name, params, annotations, opts)
    ]

    {:ok, manifests}
  end

  defp create_service(system, ns, name) do
    monitor_name = "#{system}-monitor"

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => monitor_name,
        "namespace" => ns,
        "labels" => %{"app" => monitor_name, "actor-system" => system}
      },
      "spec" => %{
        "ports" => [
          %{"name" => "monitor-http", "port" => 8090, "targetPort" => 8090}
        ],
        "selector" => %{"app" => monitor_name, "actor-system" => system}
      }
    }
  end

  defp create_deployment(system, ns, name, params, annotations, opts) do
    monitor_name = "#{system}-monitor"
    replicas = 1

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "name" => monitor_name,
        "namespace" => ns,
        "labels" => %{"app" => monitor_name, "actor-system" => system}
      },
      "spec" => %{
        "replicas" => replicas,
        "selector" => %{
          "matchLabels" => %{"actor-system" => system}
        },
        "strategy" => %{
          "type" => "RollingUpdate",
          "rollingUpdate" => %{
            "maxSurge" => "50%",
            "maxUnavailable" => 0
          }
        },
        "template" => %{
          "metadata" => %{
            "annotations" => %{
              "prometheus.io/port" => "8090",
              "prometheus.io/path" => "/metrics",
              "prometheus.io/scrape" => "true"
            },
            "labels" => %{
              "app" => monitor_name,
              "actor-system" => system
            }
          },
          "spec" => %{
            "affinity" => build_affinity(system, name),
            "containers" =>
              get_containers(
                system,
                name,
                annotations
              ),
            "initContainers" => [
              %{
                "name" => "init-certificates",
                "image" => "#{annotations.proxy_init_container_image_tag}",
                "args" => [
                  "--environment",
                  :prod,
                  "--secret",
                  "tls-certs",
                  "--namespace",
                  "#{ns}",
                  "--service",
                  "#{system}",
                  "--to",
                  "#{ns}"
                ],
                "env" => [
                  %{
                    "name" => "RELEASE_DISTRIBUTION",
                    "value" => "none"
                  }
                ]
              }
            ],
            "serviceAccountName" => "#{system}-sa",
            "volumes" => @default_certs_volume
          }
        }
      }
    }
  end

  defp build_affinity(system, app_name) do
    %{
      "podAffinity" => %{
        "preferredDuringSchedulingIgnoredDuringExecution" => [
          %{
            "weight" => 50,
            "podAffinityTerm" => %{
              "labelSelector" => %{
                "matchExpressions" => [
                  %{
                    "key" => "actor-system",
                    "operator" => "In",
                    "values" => [
                      system
                    ]
                  }
                ]
              },
              "topologyKey" => "kubernetes.io/hostname"
            }
          }
        ]
      },
      "podAntiAffinity" => %{
        "preferredDuringSchedulingIgnoredDuringExecution" => [
          %{
            "weight" => 100,
            "podAffinityTerm" => %{
              "labelSelector" => %{
                "matchExpressions" => [
                  %{
                    "key" => "app",
                    "operator" => "In",
                    "values" => [
                      app_name
                    ]
                  }
                ]
              },
              "topologyKey" => "kubernetes.io/hostname"
            }
          }
        ]
      }
    }
  end

  defp get_containers(system, name, annotations) do
    proxy_http_port = 8090

    monitor_ports = [
      %{"containerPort" => 4369, "name" => "epmd"},
      %{"containerPort" => proxy_http_port, "name" => "monitor-http"}
    ]

    monitor_container =
      %{
        "name" => "monitor",
        "image" => @default_monitor_image,
        "env" => @default_monitor_envs,
        "envFrom" => [
          %{
            "configMapRef" => %{
              "name" => "#{name}-sidecar-cm"
            }
          },
          %{
            "secretRef" => %{
              "name" => "#{system}-secret"
            }
          }
        ],
        "ports" => monitor_ports,
        "resources" => @default_monitor_resources
      }

    [
      monitor_container
    ]
  end
end
