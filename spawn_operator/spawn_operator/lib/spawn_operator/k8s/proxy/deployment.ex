defmodule SpawnOperator.K8s.Proxy.Deployment do
  @moduledoc false

  require Logger

  @behaviour SpawnOperator.K8s.Manifest

  @default_actor_host_function_env [
    %{
      "name" => "RELEASE_NAME",
      "value" => "proxy"
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
      "name" => "SPAWN_PROXY_PORT",
      "value" => "9001"
    },
    %{
      "name" => "SPAWN_PROXY_INTERFACE",
      "value" => "0.0.0.0"
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

  @default_actor_host_function_replicas 1

  @default_actor_host_resources %{
    "requests" => %{
      "cpu" => "100m",
      "memory" => "80Mi",
      "ephemeral-storage" => "1M"
    }
  }

  @default_proxy_resources %{
    "requests" => %{
      "cpu" => "50m",
      "memory" => "80Mi",
      "ephemeral-storage" => "1M"
    }
  }

  @default_termination_period_seconds 405

  @impl true
  def manifest(resource, _opts \\ []), do: gen_deployment(resource)

  defp gen_deployment(
         %{
           system: system,
           namespace: ns,
           name: name,
           params: params,
           labels: _labels,
           annotations: annotations
         } = _resource
       ) do
    host_params = Map.get(params, "host")
    task_actors_config = %{"taskActors" => Map.get(host_params, "taskActors", %{})}
    IO.inspect(task_actors_config, label: "Config ------------------------")
    topology = Map.get(params, "topology", %{})

    replicas = max(1, Map.get(params, "replicas", @default_actor_host_function_replicas))
    embedded = Map.get(host_params, "embedded", false)

    maybe_warn_wrong_volumes(params, host_params)

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
              "prometheus.io/port" => "#{annotations.proxy_http_port}",
              "prometheus.io/path" => "/metrics",
              "prometheus.io/scrape" => "true"
            },
            "labels" => %{
              "app" => name,
              "actor-system" => system
            }
          },
          "spec" =>
            %{
              "affinity" => Map.get(topology, "affinity", build_affinity(system, name)),
              "containers" =>
                get_containers(
                  embedded,
                  system,
                  name,
                  host_params,
                  annotations,
                  task_actors_config
                ),
              "initContainers" => [
                %{
                  "name" => "init-certificates",
                  "image" => "#{annotations.proxy_init_container_image_tag}",
                  "env" => [
                    %{"containerPort" => 4369, "name" => "epmd"}
                  ],
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
              "serviceAccountName" => "#{system}-sa"
            }
            |> maybe_put_node_selector(topology)
            |> maybe_put_node_tolerations(topology)
            |> maybe_put_volumes(params)
            |> maybe_set_termination_period(params)
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

  defp get_containers(true, system, name, host_params, annotations, task_actors_config) do
    actor_host_function_image = Map.get(host_params, "image")

    updated_default_envs =
      @default_actor_host_function_env ++
        [
          %{
            "name" => "RELEASE_COOKIE",
            "valueFrom" => %{
              "secretKeyRef" => %{"name" => "#{system}-secret", "key" => "RELEASE_COOKIE"}
            }
          }
        ]

    actor_host_function_envs =
      if is_nil(task_actors_config) || List.first(Map.values(task_actors_config)) == %{} do
        Map.get(host_params, "env", []) ++ updated_default_envs
      else
        Map.get(host_params, "env", []) ++
          updated_default_envs ++
          build_task_env(task_actors_config)
      end

    proxy_http_port = String.to_integer(annotations.proxy_http_port)

    proxy_actor_host_function_ports = [
      %{"containerPort" => 4369, "name" => "epmd"},
      %{"containerPort" => proxy_http_port, "name" => "proxy-http"}
    ]

    actor_host_function_ports = Map.get(host_params, "ports", [])
    actor_host_function_ports = actor_host_function_ports ++ proxy_actor_host_function_ports

    actor_host_function_resources =
      Map.get(host_params, "resources", @default_actor_host_resources)

    host_and_proxy_container =
      %{
        "name" => "actorhost",
        "image" => actor_host_function_image,
        "env" => actor_host_function_envs,
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
        "ports" => actor_host_function_ports,
        "resources" => actor_host_function_resources
      }
      |> maybe_put_volume_mounts_to_host_container(host_params)

    [
      host_and_proxy_container
    ]
  end

  defp get_containers(false, system, name, host_params, annotations, task_actors_config) do
    actor_host_function_image = Map.get(host_params, "image")

    updated_default_envs =
      @default_actor_host_function_env ++
        [
          %{
            "name" => "RELEASE_COOKIE",
            "valueFrom" => %{
              "secretKeyRef" => %{"name" => "#{system}-secret", "key" => "RELEASE_COOKIE"}
            }
          }
        ]

    actor_host_function_envs =
      Map.get(host_params, "env", []) ++
      updated_default_envs

    actor_host_function_resources =
      Map.get(host_params, "resources", @default_actor_host_resources)

    proxy_http_port = String.to_integer(annotations.proxy_http_port)

    proxy_actor_host_function_ports = [
      %{"containerPort" => 4369, "name" => "epmd"},
      %{"containerPort" => proxy_http_port, "name" => "proxy-http"}
    ]

    envs =
      if is_nil(task_actors_config) || List.first(Map.values(task_actors_config)) == %{} do
        updated_default_envs
      else
        updated_default_envs ++ build_task_env(task_actors_config)
      end

    proxy_container =
      %{
        "name" => "sidecar",
        "image" => "#{annotations.proxy_image_tag}",
        "imagePullPolicy" => "Always",
        "env" => envs,
        "ports" => proxy_actor_host_function_ports,
        "livenessProbe" => %{
          "httpGet" => %{
            "path" => "/health/liveness",
            "port" => proxy_http_port,
            "scheme" => "HTTP"
          },
          "failureThreshold" => 3,
          "initialDelaySeconds" => 10,
          "periodSeconds" => 10,
          "successThreshold" => 1,
          "timeoutSeconds" => 30
        },
        "readinessProbe" => %{
          "httpGet" => %{
            "path" => "/health/readiness",
            "port" => proxy_http_port,
            "scheme" => "HTTP"
          },
          "failureThreshold" => 1,
          "initialDelaySeconds" => 5,
          "periodSeconds" => 5,
          "successThreshold" => 1,
          "timeoutSeconds" => 5
        },
        "resources" => @default_proxy_resources,
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
        ]
      }
      |> maybe_put_volume_mounts_to_host_container(host_params)

    host_container =
      %{
        "name" => "actorhost",
        "image" => actor_host_function_image,
        "env" => actor_host_function_envs,
        "resources" => actor_host_function_resources
      }
      |> maybe_put_ports_to_host_container(host_params)
      |> maybe_put_volume_mounts_to_host_container(host_params)

    [
      proxy_container,
      host_container
    ]
  end

  defp build_task_env(task_actors_config) do
    value =
      task_actors_config
      |> Jason.encode!()
      |> Base.encode32()

    [
      %{"name" => "SPAWN_PROXY_TASK_CONFIG", "value" => value}
    ]
  end

  defp maybe_put_node_selector(spec, %{"nodeSelector" => selectors} = _topology) do
    Map.merge(spec, %{"nodeSelector" => selectors})
  end

  defp maybe_put_node_selector(spec, _), do: spec

  defp maybe_put_node_tolerations(spec, %{"tolerations" => tolerations} = _topology) do
    Map.merge(spec, %{"tolerations" => tolerations})
  end

  defp maybe_put_node_tolerations(spec, _), do: spec

  defp maybe_put_ports_to_host_container(spec, %{"ports" => ports}) do
    Map.put(spec, "ports", ports)
  end

  defp maybe_put_ports_to_host_container(spec, _), do: spec

  defp maybe_set_termination_period(spec, %{
         "terminationGracePeriodSeconds" => terminationGracePeriodSeconds
       }) do
    Map.put(
      spec,
      "terminationGracePeriodSeconds",
      terminationGracePeriodSeconds || @default_termination_period_seconds
    )
  end

  defp maybe_set_termination_period(spec, _) do
    Map.put(spec, "terminationGracePeriodSeconds", @default_termination_period_seconds)
  end

  defp maybe_put_volumes(spec, %{"volumes" => volumes}) do
    volumes =
      volumes ++
        [
          %{
            "name" => "certs",
            "secret" => %{"secretName" => "tls-certs", "optional" => true}
          }
        ]

    Map.merge(spec, %{"volumes" => volumes})
  end

  defp maybe_put_volumes(spec, _) do
    Map.put(spec, "volumes", [
      %{
        "name" => "certs",
        "secret" => %{"secretName" => "tls-certs", "optional" => true}
      }
    ])
  end

  defp maybe_put_volume_mounts_to_host_container(spec, %{"volumeMounts" => volumeMounts}) do
    volumeMounts = volumeMounts ++ [%{"name" => "certs", "mountPath" => "/app/certs"}]
    Map.merge(spec, %{"volumeMounts" => volumeMounts})
  end

  defp maybe_put_volume_mounts_to_host_container(spec, _) do
    Map.put(spec, "volumeMounts", [%{"name" => "certs", "mountPath" => "/app/certs"}])
  end

  defp maybe_warn_wrong_volumes(params, host_params) do
    volumes = Map.get(params, "volumes", [])

    host_params
    |> Map.get("volumeMounts", [])
    |> Enum.each(fn mount ->
      if !Enum.find(volumes, &(&1["name"] == mount["name"])) do
        Logger.warning("Not found volume registered for #{mount["name"]}")
      end
    end)
  end
end
