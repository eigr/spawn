defmodule DeploymentTest do
  use ExUnit.Case
  use Bonny.Axn.Test

  alias SpawnOperator.K8s.Proxy.Deployment

  import SpawnOperator.FactoryTest

  setup do
    simple_host = build_simple_actor_host()
    simple_host_with_ports = build_simple_actor_host_with_ports()
    simple_actor_host_with_volume_mounts = build_simple_actor_host_with_volume_mounts()
    embedded_actor_host = build_embedded_actor_host()
    embedded_actor_host_with_volume_mounts = build_embedded_actor_host_with_volume_mounts()

    %{
      simple_host: simple_host,
      simple_host_with_ports: simple_host_with_ports,
      simple_actor_host_with_volume_mounts: simple_actor_host_with_volume_mounts,
      embedded_actor_host: embedded_actor_host,
      embedded_actor_host_with_volume_mounts: embedded_actor_host_with_volume_mounts
    }
  end

  describe "manifest/1" do
    test "generate embedded deployment with defaults", ctx do
      %{
        embedded_actor_host: embedded_actor_host
      } = ctx

      assert %{
               "apiVersion" => "apps/v1",
               "kind" => "Deployment",
               "metadata" => %{
                 "labels" => %{"actor-system" => "spawn-system", "app" => "spawn-test"},
                 "name" => "spawn-test",
                 "namespace" => "default"
               },
               "spec" => %{
                 "replicas" => 1,
                 "selector" => %{
                   "matchLabels" => %{"actor-system" => "spawn-system", "app" => "spawn-test"}
                 },
                 "strategy" => %{
                   "rollingUpdate" => %{"maxSurge" => "50%", "maxUnavailable" => 0},
                   "type" => "RollingUpdate"
                 },
                 "template" => %{
                   "metadata" => %{
                     "annotations" => %{
                       "prometheus.io/path" => "/metrics",
                       "prometheus.io/port" => "9001",
                       "prometheus.io/scrape" => "true"
                     },
                     "labels" => %{"actor-system" => "spawn-system", "app" => "spawn-test"}
                   },
                   "spec" => %{
                     "affinity" => %{
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
                                     "values" => ["spawn-system"]
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
                                     "values" => ["spawn-test"]
                                   }
                                 ]
                               },
                               "topologyKey" => "kubernetes.io/hostname"
                             }
                           }
                         ]
                       }
                     },
                     "containers" => [
                       %{
                         "env" => [
                           %{"name" => "RELEASE_NAME", "value" => "spawn"},
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
                           %{"name" => "SPAWN_PROXY_INTERFACE", "value" => "0.0.0.0"},
                           %{"name" => "RELEASE_DISTRIBUTION", "value" => "name"},
                           %{"name" => "RELEASE_NODE", "value" => "$(RELEASE_NAME)@$(POD_IP)"}
                         ],
                         "envFrom" => [
                           %{"configMapRef" => %{"name" => "spawn-test-sidecar-cm"}},
                           %{"secretRef" => %{"name" => "spawn-system-secret"}}
                         ],
                         "image" => "eigr/spawn-test:latest",
                         "name" => "actorhost",
                         "ports" => [
                           %{"containerPort" => 4369, "name" => "epmd"},
                           %{"containerPort" => 9001, "name" => "proxy-http"}
                         ],
                         "resources" => %{
                           "requests" => %{
                             "cpu" => "100m",
                             "ephemeral-storage" => "1M",
                             "memory" => "80Mi"
                           }
                         },
                         "volumeMounts" => [%{"mountPath" => "/app/certs", "name" => "certs"}]
                       }
                     ],
                     "terminationGracePeriodSeconds" => 405,
                     "initContainers" => [
                       %{
                         "args" => [
                           "--environment",
                           :prod,
                           "--secret",
                           "tls-certs",
                           "--namespace",
                           "default",
                           "--service",
                           "spawn-system",
                           "--to",
                           "default"
                         ],
                         "image" => "ghcr.io/eigr/spawn-initializer:1.4.2",
                         "name" => "init-certificates"
                       }
                     ],
                     "serviceAccountName" => "spawn-system-sa",
                     "volumes" => [
                       %{
                         "name" => "certs",
                         "secret" => %{"optional" => true, "secretName" => "tls-certs"}
                       }
                     ]
                   }
                 }
               }
             } == build_host_deploy(embedded_actor_host)
    end

    test "generate embedded deployment with volumeMount", ctx do
      %{
        embedded_actor_host_with_volume_mounts: embedded_actor_host_with_volume_mounts
      } = ctx

      assert %{
               "apiVersion" => "apps/v1",
               "kind" => "Deployment",
               "metadata" => %{
                 "labels" => %{"actor-system" => "spawn-system", "app" => "spawn-test"},
                 "name" => "spawn-test",
                 "namespace" => "default"
               },
               "spec" => %{
                 "replicas" => 1,
                 "selector" => %{
                   "matchLabels" => %{"actor-system" => "spawn-system", "app" => "spawn-test"}
                 },
                 "strategy" => %{
                   "rollingUpdate" => %{"maxSurge" => "50%", "maxUnavailable" => 0},
                   "type" => "RollingUpdate"
                 },
                 "template" => %{
                   "metadata" => %{
                     "annotations" => %{
                       "prometheus.io/path" => "/metrics",
                       "prometheus.io/port" => "9001",
                       "prometheus.io/scrape" => "true"
                     },
                     "labels" => %{"actor-system" => "spawn-system", "app" => "spawn-test"}
                   },
                   "spec" => %{
                     "affinity" => %{
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
                                     "values" => ["spawn-system"]
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
                                     "values" => ["spawn-test"]
                                   }
                                 ]
                               },
                               "topologyKey" => "kubernetes.io/hostname"
                             }
                           }
                         ]
                       }
                     },
                     "containers" => [
                       %{
                         "env" => [
                           %{"name" => "RELEASE_NAME", "value" => "spawn"},
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
                           %{"name" => "SPAWN_PROXY_INTERFACE", "value" => "0.0.0.0"},
                           %{"name" => "RELEASE_DISTRIBUTION", "value" => "name"},
                           %{"name" => "RELEASE_NODE", "value" => "$(RELEASE_NAME)@$(POD_IP)"}
                         ],
                         "envFrom" => [
                           %{"configMapRef" => %{"name" => "spawn-test-sidecar-cm"}},
                           %{"secretRef" => %{"name" => "spawn-system-secret"}}
                         ],
                         "image" => "eigr/spawn-test:latest",
                         "name" => "actorhost",
                         "ports" => [
                           %{"containerPort" => 4369, "name" => "epmd"},
                           %{"containerPort" => 9001, "name" => "proxy-http"}
                         ],
                         "resources" => %{
                           "requests" => %{
                             "cpu" => "100m",
                             "ephemeral-storage" => "1M",
                             "memory" => "80Mi"
                           }
                         },
                         "volumeMounts" => [
                           %{"mountPath" => "/app/certs", "name" => "certs"},
                           %{"mountPath" => "/app/extra", "name" => "extra-volume"}
                         ]
                       }
                     ],
                     "terminationGracePeriodSeconds" => 405,
                     "initContainers" => [
                       %{
                         "args" => [
                           "--environment",
                           :prod,
                           "--secret",
                           "tls-certs",
                           "--namespace",
                           "default",
                           "--service",
                           "spawn-system",
                           "--to",
                           "default"
                         ],
                         "image" => "ghcr.io/eigr/spawn-initializer:1.4.2",
                         "name" => "init-certificates"
                       }
                     ],
                     "serviceAccountName" => "spawn-system-sa",
                     "volumes" => [
                       %{
                         "name" => "certs",
                         "secret" => %{"optional" => true, "secretName" => "tls-certs"}
                       },
                       %{
                         "name" => "extra-volume",
                         "emptyDir" => %{}
                       }
                     ]
                   }
                 }
               }
             } == build_host_deploy(embedded_actor_host_with_volume_mounts)
    end

    # Additional tests for other SDK values, secrets, configurations, etc.
    # ...

    for sdk <- ~w(dart elixir java python rust springboot nodejs unknown)a do
      test "generate deployment for SDK #{sdk}", ctx do
        %{
          simple_host: simple_host
        } = ctx

        expected_resources =
          case sdk do
            "dart" -> %{"requests" => %{"cpu" => "100m", "memory" => "64Mi"}}
            "elixir" -> %{"requests" => %{"cpu" => "200m", "memory" => "128Mi"}}
            "java" -> %{"requests" => %{"cpu" => "300m", "memory" => "256Mi"}}
            "python" -> %{"requests" => %{"cpu" => "150m", "memory" => "128Mi"}}
            "rust" -> %{"requests" => %{"cpu" => "200m", "memory" => "256Mi"}}
            "springboot" -> %{"requests" => %{"cpu" => "400m", "memory" => "512Mi"}}
            "nodejs" -> %{"requests" => %{"cpu" => "150m", "memory" => "128Mi"}}
            _ -> %{"requests" => %{"cpu" => "100m", "memory" => "64Mi"}}
          end

        assert %{
                 "apiVersion" => "apps/v1",
                 "kind" => "Deployment",
                 "metadata" => %{
                   "labels" => %{"actor-system" => "spawn-system", "app" => "spawn-test"},
                   "name" => "spawn-test",
                   "namespace" => "default"
                 },
                 "spec" => %{
                   "replicas" => 1,
                   "selector" => %{
                     "matchLabels" => %{"actor-system" => "spawn-system", "app" => "spawn-test"}
                   },
                   "strategy" => %{
                     "rollingUpdate" => %{"maxSurge" => "50%", "maxUnavailable" => 0},
                     "type" => "RollingUpdate"
                   },
                   "template" => %{
                     "metadata" => %{
                       "annotations" => %{
                         "prometheus.io/path" => "/metrics",
                         "prometheus.io/port" => "9001",
                         "prometheus.io/scrape" => "true"
                       },
                       "labels" => %{"actor-system" => "spawn-system", "app" => "spawn-test"}
                     },
                     "spec" => %{
                       "containers" => [
                         %{
                           "env" => [
                             %{"name" => "RELEASE_NAME", "value" => "spawn"},
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
                             %{"name" => "SPAWN_PROXY_INTERFACE", "value" => "0.0.0.0"},
                             %{"name" => "RELEASE_DISTRIBUTION", "value" => "name"},
                             %{"name" => "RELEASE_NODE", "value" => "$(RELEASE_NAME)@$(POD_IP)"}
                           ],
                           "image" => "eigr/spawn-test:latest",
                           "name" => "actorhost",
                           "ports" => [
                             %{"containerPort" => 4369, "name" => "epmd"},
                             %{"containerPort" => 9001, "name" => "proxy-http"}
                           ],
                           "resources" => expected_resources
                         }
                       ],
                       "terminationGracePeriodSeconds" => 405,
                       "serviceAccountName" => "spawn-system-sa"
                     }
                   }
                 }
               } == build_host_deploy(%{simple_host | params: %{sdk: sdk}})
      end
    end
  end
end
