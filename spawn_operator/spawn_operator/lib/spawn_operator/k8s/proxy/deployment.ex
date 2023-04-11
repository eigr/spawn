defmodule SpawnOperator.K8s.Proxy.Deployment do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @default_actor_host_function_env [
    %{
      "name" => "NAMESPACE",
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

  @default_actor_host_function_resources %{
    "limits" => %{
      "memory" => "1024Mi"
    },
    "requests" => %{
      "memory" => "80Mi"
    }
  }

  @default_termination_period_seconds 140

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

    replicas = Map.get(params, "replicas", @default_actor_host_function_replicas)

    replicas =
      if replicas <= 1 do
        1
      else
        replicas
      end

    embedded = Map.get(host_params, "embedded", false)

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
            "maxSurge" => "50%",
            "maxUnavailable" => "50%"
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
              "containers" => get_containers(embedded, system, name, host_params, annotations),
              "terminationGracePeriodSeconds" => @default_termination_period_seconds
            }
            |> maybe_put_volumes(params)
        }
      }
    }
  end

  defp get_containers(true, system, name, host_params, annotations) do
    actor_host_function_image = Map.get(host_params, "image")

    actor_host_function_envs =
      Map.get(host_params, "env", []) ++
        [
          %{
            "name" => "RELEASE_NAME",
            "value" => name
          }
        ] ++
        @default_actor_host_function_env

    proxy_http_port = String.to_integer(annotations.proxy_http_port)

    proxy_actor_host_function_ports = [
      %{"containerPort" => 4369, "name" => "epmd"},
      %{"containerPort" => proxy_http_port, "name" => "proxy-http"}
    ]

    actor_host_function_ports = Map.get(host_params, "ports", [])
    actor_host_function_ports = actor_host_function_ports ++ proxy_actor_host_function_ports

    actor_host_function_resources =
      Map.get(host_params, "resources", @default_actor_host_function_resources)

    host_and_proxy_container =
      %{
        "name" => "actor-host-function",
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

  defp get_containers(false, system, name, host_params, annotations) do
    actor_host_function_image = Map.get(host_params, "image")

    actor_host_function_envs =
      Map.get(host_params, "env", []) ++
        @default_actor_host_function_env

    proxy_envs =
      [
        %{
          "name" => "RELEASE_NAME",
          "value" => name
        }
      ] ++
        @default_actor_host_function_env

    actor_host_function_resources =
      Map.get(host_params, "resources", @default_actor_host_function_resources)

    proxy_http_port = String.to_integer(annotations.proxy_http_port)

    proxy_actor_host_function_ports = [
      %{"containerPort" => 4369, "name" => "epmd"},
      %{"containerPort" => proxy_http_port, "name" => "proxy-http"}
    ]

    proxy_container = %{
      "name" => "spawn-sidecar",
      "image" => "#{annotations.proxy_image_tag}",
      "env" => proxy_envs,
      "ports" => proxy_actor_host_function_ports,
      "livenessProbe" => %{
        "failureThreshold" => 10,
        "httpGet" => %{
          "path" => "/health/liveness",
          "port" => proxy_http_port,
          "scheme" => "HTTP"
        },
        "initialDelaySeconds" => 5,
        "periodSeconds" => 60,
        "successThreshold" => 1,
        "timeoutSeconds" => 30
      },
      "readinessProbe" => %{
        "httpGet" => %{
          "path" => "/health/readiness",
          "port" => proxy_http_port,
          "scheme" => "HTTP"
        },
        "initialDelaySeconds" => 5,
        "periodSeconds" => 5,
        "successThreshold" => 1,
        "timeoutSeconds" => 5
      },
      "resources" => actor_host_function_resources,
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

    host_container =
      %{
        "name" => "actor-host-function",
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

  defp maybe_put_ports_to_host_container(spec, %{"ports" => ports}) do
    Map.put(spec, "ports", ports)
  end

  defp maybe_put_ports_to_host_container(spec, _), do: spec

  defp maybe_put_volumes(spec, %{"volumes" => volumes}) do
    Map.put(spec, "volumes", volumes)
  end

  defp maybe_put_volumes(spec, _), do: spec

  defp maybe_put_volume_mounts_to_host_container(spec, %{"volumeMounts" => volumeMounts}) do
    Map.put(spec, "volumeMounts", volumeMounts)
  end

  defp maybe_put_volume_mounts_to_host_container(spec, _), do: spec
end
