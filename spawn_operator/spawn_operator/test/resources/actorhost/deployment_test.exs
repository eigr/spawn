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
                 "replicas" => 2,
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
                                     "values" => [
                                       "spawn-system"
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
                                       "spawn-test"
                                     ]
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
                     "securityContext" => %{
                       "allowPrivilegeEscalation" => false,
                       "fsGroup" => 1000,
                       "readOnlyRootFilesystem" => true,
                       "runAsNonRoot" => true,
                       "runAsUser" => 1000
                     },
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
                 "replicas" => 2,
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
                                     "values" => [
                                       "spawn-system"
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
                                       "spawn-test"
                                     ]
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
                           %{"mountPath" => "/home/example", "name" => "volume-name"},
                           %{"mountPath" => "/app/certs", "name" => "certs"}
                         ]
                       }
                     ],
                     "terminationGracePeriodSeconds" => 405,
                     "securityContext" => %{
                       "allowPrivilegeEscalation" => false,
                       "fsGroup" => 1000,
                       "readOnlyRootFilesystem" => true,
                       "runAsNonRoot" => true,
                       "runAsUser" => 1000
                     },
                     "volumes" => [
                       %{"emptyDir" => "{}", "name" => "volume-name"},
                       %{
                         "name" => "certs",
                         "secret" => %{"optional" => true, "secretName" => "tls-certs"}
                       }
                     ],
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
                     "serviceAccountName" => "spawn-system-sa"
                   }
                 }
               }
             } == build_host_deploy(embedded_actor_host_with_volume_mounts)
    end

    test "generate deployment with defaults", ctx do
      %{
        simple_host: simple_host_resource
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
                 "replicas" => 2,
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
                       "podAntiAffinity" => %{
                         "preferredDuringSchedulingIgnoredDuringExecution" => [
                           %{
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
                             },
                             "weight" => 100
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
                         "image" => _image_version,
                         "livenessProbe" => %{
                           "httpGet" => %{
                             "path" => "/health/liveness",
                             "port" => 9001,
                             "scheme" => "HTTP"
                           },
                           "failureThreshold" => 3,
                           "initialDelaySeconds" => 10,
                           "periodSeconds" => 10,
                           "successThreshold" => 1,
                           "timeoutSeconds" => 30
                         },
                         "name" => "sidecar",
                         "ports" => [
                           %{"containerPort" => 4369, "name" => "epmd"},
                           %{"containerPort" => 9001, "name" => "proxy-http"}
                         ],
                         "readinessProbe" => %{
                           "httpGet" => %{
                             "path" => "/health/readiness",
                             "port" => 9001,
                             "scheme" => "HTTP"
                           },
                           "failureThreshold" => 1,
                           "initialDelaySeconds" => 5,
                           "periodSeconds" => 5,
                           "successThreshold" => 1,
                           "timeoutSeconds" => 5
                         },
                         "resources" => %{
                           "requests" => %{
                             "cpu" => "50m",
                             "ephemeral-storage" => "1M",
                             "memory" => "80Mi"
                           }
                         }
                       },
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
                         "resources" => %{
                           "requests" => %{
                             "cpu" => "100m",
                             "ephemeral-storage" => "1M",
                             "memory" => "80Mi"
                           }
                         }
                       }
                     ],
                     "terminationGracePeriodSeconds" => 405
                   }
                 }
               }
             } = build_host_deploy(simple_host_resource)
    end

    test "generate deployment with host ports", ctx do
      %{
        simple_host_with_ports: simple_host_with_ports_resource
      } = ctx

      assert %{
               "spec" => %{
                 "template" => %{
                   "spec" => %{
                     "affinity" => %{
                       "podAntiAffinity" => %{
                         "preferredDuringSchedulingIgnoredDuringExecution" => [
                           %{
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
                             },
                             "weight" => 100
                           }
                         ]
                       }
                     },
                     "containers" => containers
                   }
                 }
               }
             } = build_host_deploy(simple_host_with_ports_resource)

      assert List.first(containers) == %{
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
               "resources" => %{
                 "requests" => %{"memory" => "80Mi", "ephemeral-storage" => "1M", "cpu" => "100m"}
               },
               "volumeMounts" => [%{"mountPath" => "/app/certs", "name" => "certs"}],
               "ports" => [
                 %{"containerPort" => 8090, "name" => "http"},
                 %{"containerPort" => 8091, "name" => "https"}
               ]
             }
    end

    test "generate deployment with host volumeMount", ctx do
      %{
        simple_actor_host_with_volume_mounts: simple_actor_host_with_volume_mounts
      } = ctx

      assert %{
               "spec" => %{
                 "template" => %{
                   "spec" => %{
                     "affinity" => %{
                       "podAntiAffinity" => %{
                         "preferredDuringSchedulingIgnoredDuringExecution" => [
                           %{
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
                             },
                             "weight" => 100
                           }
                         ]
                       }
                     },
                     "containers" => containers,
                     "volumes" => [
                       %{"emptyDir" => "{}", "name" => "volume-name"},
                       %{
                         "name" => "certs",
                         "secret" => %{"optional" => true, "secretName" => "tls-certs"}
                       }
                     ]
                   }
                 }
               }
             } = build_host_deploy(simple_actor_host_with_volume_mounts)

      assert %{
               "volumeMounts" => [
                 %{"mountPath" => "/home/example", "name" => "volume-name"},
                 %{"mountPath" => "/app/certs", "name" => "certs"}
               ]
             } = List.last(containers)
    end

    for sdk <- ~w(dart elixir java python rust springboot nodejs unknown)a do
      @global_sdk sdk
      test "generate deployment for SDK #{sdk}", ctx do
        %{
          simple_host: simple_host
        } = ctx

        expected_resources =
          case @global_sdk do
            "dart" ->
              %{"requests" => %{"cpu" => "10m", "memory" => "70Mi", "ephemeral-storage" => "1M"}}

            "elixir" ->
              %{
                "requests" => %{"cpu" => "150m", "memory" => "256Mi", "ephemeral-storage" => "1M"}
              }

            "java" ->
              %{
                "requests" => %{"cpu" => "200m", "memory" => "512Mi", "ephemeral-storage" => "1M"}
              }

            "python" ->
              %{"requests" => %{"cpu" => "10m", "memory" => "256Mi", "ephemeral-storage" => "1M"}}

            "rust" ->
              %{"requests" => %{"cpu" => "10m", "memory" => "70Mi", "ephemeral-storage" => "1M"}}

            "springboot" ->
              %{
                "requests" => %{"cpu" => "300m", "memory" => "512Mi", "ephemeral-storage" => "1M"}
              }

            "nodejs" ->
              %{
                "requests" => %{"cpu" => "150m", "memory" => "256Mi", "ephemeral-storage" => "1M"}
              }

            _ ->
              %{"requests" => %{"cpu" => "100m", "memory" => "80Mi", "ephemeral-storage" => "1M"}}
          end

        host = simple_host["spec"]["host"]
        new_simple_actor_host = Map.put(host, "sdk", Atom.to_string(@global_sdk))
        simple_host = Map.put(simple_host, "spec", %{"host" => new_simple_actor_host})

        assert %{
                 "apiVersion" => "apps/v1",
                 "kind" => "Deployment",
                 "metadata" => %{
                   "labels" => %{"actor-system" => "spawn-system", "app" => "spawn-test"},
                   "name" => "spawn-test",
                   "namespace" => "default"
                 },
                 "spec" => %{
                   "replicas" => 2,
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
                         "podAntiAffinity" => %{
                           "preferredDuringSchedulingIgnoredDuringExecution" => [
                             %{
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
                               },
                               "weight" => 100
                             }
                           ]
                         },
                         "podAffinity" => %{
                           "preferredDuringSchedulingIgnoredDuringExecution" => [
                             %{
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
                               },
                               "weight" => 50
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
                           "image" => "eigr/spawn-test:latest",
                           "name" => "actorhost",
                           "ports" => [%{"containerPort" => "9001", "name" => "http"}],
                           "resources" => expected_resources
                         },
                         %{
                           "image" => "ghcr.io/eigr/spawn-proxy:1.4.2",
                           "name" => "proxy",
                           "ports" => [%{"containerPort" => "9001", "name" => "http"}],
                           "resources" => %{
                             "requests" => %{
                               "cpu" => "50m",
                               "ephemeral-storage" => "1M",
                               "memory" => "80Mi"
                             }
                           }
                         }
                       ],
                       "terminationGracePeriodSeconds" => 405,
                       "initContainers" => [
                         %{
                           "args" => [
                             "--environment",
                             "prod",
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
                       "securityContext" => %{
                         "allowPrivilegeEscalation" => false,
                         "fsGroup" => 1000,
                         "readOnlyRootFilesystem" => true,
                         "runAsNonRoot" => true,
                         "runAsUser" => 1000
                       },
                       "serviceAccountName" => "spawn-system-sa"
                     }
                   }
                 }
               } == build_host_deploy(simple_host)
      end
    end
  end

  defp build_host_deploy(resource) do
    SpawnOperator.get_args(resource)
    |> Deployment.manifest()
  end
end
