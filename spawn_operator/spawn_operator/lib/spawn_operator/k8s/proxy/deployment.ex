defmodule SpawnOperator.K8s.Proxy.Deployment do
  @moduledoc """
  Handles the generation of Kubernetes Deployment manifests for the Spawn system.
  """
  require Logger

  @behaviour SpawnOperator.K8s.Manifest

  @default_actor_host_function_env [
    %{"name" => "RELEASE_NAME", "value" => "spawn"},
    %{
      "name" => "NAMESPACE",
      "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
    },
    %{
      "name" => "POD_IP",
      "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
    },
    %{"name" => "SPAWN_PROXY_PORT", "value" => "9001"},
    %{"name" => "SPAWN_PROXY_INTERFACE", "value" => "0.0.0.0"},
    %{"name" => "RELEASE_DISTRIBUTION", "value" => "name"},
    %{"name" => "RELEASE_NODE", "value" => "$(RELEASE_NAME)@$(POD_IP)"}
  ]

  @default_actor_host_function_replicas 2

  @actor_host_resources_by_sdk %{
    "dart" => %{
      "requests" => %{
        "cpu" => "10m",
        "memory" => "70Mi",
        "ephemeral-storage" => "1M"
      }
    },
    "elixir" => %{
      "requests" => %{
        "cpu" => "150m",
        "memory" => "256Mi",
        "ephemeral-storage" => "2M"
      }
    },
    "go" => %{
      "requests" => %{
        "cpu" => "50m",
        "memory" => "128Mi",
        "ephemeral-storage" => "2M"
      }
    },
    "java" => %{
      "requests" => %{
        "cpu" => "200m",
        "memory" => "512Mi",
        "ephemeral-storage" => "2M"
      }
    },
    "python" => %{
      "requests" => %{
        "cpu" => "10m",
        "memory" => "256Mi",
        "ephemeral-storage" => "1M"
      }
    },
    "rust" => %{
      "requests" => %{
        "cpu" => "10m",
        "memory" => "70Mi",
        "ephemeral-storage" => "1M"
      }
    },
    "springboot" => %{
      "requests" => %{
        "cpu" => "300m",
        "memory" => "512Mi",
        "ephemeral-storage" => "2M"
      }
    },
    "nodejs" => %{
      "requests" => %{
        "cpu" => "150m",
        "memory" => "256Mi",
        "ephemeral-storage" => "1M"
      }
    },
    "unknown" => %{
      "requests" => %{
        "cpu" => "100m",
        "memory" => "80Mi",
        "ephemeral-storage" => "1M"
      }
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

  @default_security_context %{
    "allowPrivilegeEscalation" => false,
    "readOnlyRootFilesystem" => true,
    "runAsNonRoot" => true,
    "runAsUser" => 1000,
    "fsGroup" => 1000
  }

  @impl true
  @doc """
  Generates the Kubernetes Deployment manifest for the given resource.
  """
  def manifest(resource, _opts \\ []), do: gen_deployment(resource)

  @doc false
  defp gen_deployment(%{
         system: system,
         namespace: ns,
         name: name,
         params: params,
         annotations: annotations
       }) do
    host_params = Map.get(params, "host", %{})
    replicas = max(2, Map.get(params, "replicas", @default_actor_host_function_replicas))
    embedded = Map.get(host_params, "embedded", false)
    sdk = Map.get(params, "sdk", "unknown")

    actor_host_resources =
      Map.get(@actor_host_resources_by_sdk, sdk, @actor_host_resources_by_sdk["unknown"])

    maybe_warn_wrong_volumes(params, host_params)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => metadata(name, ns, system),
      "spec" =>
        spec(system, name, ns, replicas, host_params, embedded, annotations, actor_host_resources)
    }
  end

  @doc false
  defp metadata(name, ns, system) do
    %{
      "name" => name,
      "namespace" => ns,
      "labels" => %{"app" => name, "actor-system" => system}
    }
  end

  @doc false
  defp spec(system, name, ns, replicas, host_params, embedded, annotations, actor_host_resources) do
    %{
      "replicas" => replicas,
      "selector" => selector(system, name),
      "strategy" => strategy(),
      "template" =>
        template(system, name, ns, host_params, embedded, annotations, actor_host_resources)
    }
  end

  @doc false
  defp selector(system, name),
    do: %{"matchLabels" => %{"app" => name, "actor-system" => system}}

  @doc false
  defp strategy do
    %{
      "type" => "RollingUpdate",
      "rollingUpdate" => %{
        "maxSurge" => "50%",
        "maxUnavailable" => 0
      }
    }
  end

  @doc false
  defp template(system, name, ns, host_params, embedded, annotations, actor_host_resources) do
    %{
      "metadata" => template_metadata(name, system, annotations.proxy_http_port),
      "spec" =>
        base_spec(system, name, ns, host_params, embedded, annotations, actor_host_resources)
        |> maybe_put_volumes(host_params)
        |> maybe_set_termination_period(host_params)
        |> maybe_set_security_context(host_params)
    }
  end

  @doc false
  defp template_metadata(name, system, proxy_http_port) do
    %{
      "annotations" => %{
        "prometheus.io/port" => "#{proxy_http_port}",
        "prometheus.io/path" => "/metrics",
        "prometheus.io/scrape" => "true"
      },
      "labels" => %{
        "app" => name,
        "actor-system" => system
      }
    }
  end

  @doc false
  defp base_spec(system, name, ns, host_params, embedded, annotations, actor_host_resources) do
    %{
      "affinity" => Map.get(host_params, "affinity", build_affinity(system, name)),
      "containers" =>
        get_containers(embedded, system, name, host_params, annotations, actor_host_resources),
      "initContainers" => init_containers(ns, system),
      "serviceAccountName" => "#{system}-sa"
    }
  end

  @doc false
  defp init_containers(ns, system) do
    [
      %{
        "name" => "init-certificates",
        "image" => "ghcr.io/eigr/spawn-initializer:1.4.2",
        "args" => [
          "--environment",
          "prod",
          "--secret",
          "tls-certs",
          "--namespace",
          ns,
          "--service",
          system,
          "--to",
          ns
        ]
      }
    ]
  end

  @doc false
  defp build_affinity(system, app_name) do
    %{
      "podAffinity" => %{
        "preferredDuringSchedulingIgnoredDuringExecution" => [
          affinity_term(system, "kubernetes.io/hostname", 50)
        ]
      },
      "podAntiAffinity" => %{
        "preferredDuringSchedulingIgnoredDuringExecution" => [
          affinity_term(app_name, "kubernetes.io/hostname", 100)
        ]
      }
    }
  end

  @doc false
  defp affinity_term(key, topology, weight) do
    %{
      "weight" => weight,
      "podAffinityTerm" => %{
        "labelSelector" => %{
          "matchExpressions" => [
            %{
              "key" => key,
              "operator" => "In",
              "values" => [key]
            }
          ]
        },
        "topologyKey" => topology
      }
    }
  end

  @doc false
  defp get_containers(true, system, name, host_params, annotations, actor_host_resources) do
    [create_actor_host_container(system, name, host_params, annotations, actor_host_resources)]
  end

  @doc false
  defp get_containers(false, system, name, host_params, annotations, actor_host_resources) do
    [
      create_actor_host_container(system, name, host_params, annotations, actor_host_resources),
      create_proxy_container(annotations)
    ]
  end

  @doc false
  defp create_actor_host_container(_system, _name, host_params, annotations, actor_host_resources) do
    %{
      "name" => "actorhost",
      "image" => Map.fetch!(host_params, "image"),
      "env" => @default_actor_host_function_env ++ Map.get(host_params, "env", []),
      "resources" => actor_host_resources,
      "ports" => [
        %{"name" => "http", "containerPort" => annotations.proxy_http_port}
      ]
    }
  end

  @doc false
  defp create_proxy_container(annotations) do
    %{
      "name" => "proxy",
      "image" => "ghcr.io/eigr/spawn-proxy:1.4.2",
      "resources" => @default_proxy_resources,
      "ports" => [
        %{"name" => "http", "containerPort" => annotations.proxy_http_port}
      ]
    }
  end

  @doc false
  defp maybe_put_volumes(spec, %{"volumes" => volumes}) do
    Map.put(spec, "volumes", volumes)
  end

  defp maybe_put_volumes(spec, _), do: spec

  @doc false
  defp maybe_set_termination_period(spec, %{"terminationGracePeriodSeconds" => period}) do
    Map.put(spec, "terminationGracePeriodSeconds", period)
  end

  defp maybe_set_termination_period(spec, _),
    do: Map.put(spec, "terminationGracePeriodSeconds", @default_termination_period_seconds)

  @doc false
  defp maybe_set_security_context(spec, %{"securityContext" => context}) when is_map(context) do
    put_in(spec["template"]["spec"]["securityContext"], context)
  end

  defp maybe_set_security_context(spec, _),
    do: put_in(spec["template"]["spec"]["securityContext"], @default_security_context)

  @doc false
  defp maybe_warn_wrong_volumes(params, host_params) do
    volumes = Map.get(params, "volumes", [])
    volume_mounts = Map.get(host_params, "volumeMounts", [])

    cond do
      length(volumes) > 0 and length(volume_mounts) == 0 ->
        Logger.warning("Volumes are defined but no volumeMounts provided.")

      length(volume_mounts) > 0 and length(volumes) == 0 ->
        Logger.warning("VolumeMounts are defined but no volumes provided.")

      true ->
        :ok
    end
  end
end
