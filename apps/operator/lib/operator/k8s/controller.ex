defmodule Operator.K8S.Controller do
  @moduledoc false

  alias Operator.K8S.Resources.{
    ClusterIPService,
    ConfigMap,
    Deployment,
    HeadlessService,
    HPA,
    Ingress,
    LoadBalancer,
    NodePort,
    StatefulSet
  }

  @default_params %{
    "language" => "none",
    "runtime" => "grpc",
    "features" => %{
      "eventing" => false,
      "eventingMappings" => %{
        "sources" => [],
        "sinks" => []
      },
      "typeMappings" => false,
      "typeMappingsKeys" => [],
      "httpTranscode" => false,
      "httpTranscodeMappings" => [
        %{
          "serviceName" => "EigrEasterEggFakeService",
          "rpcMethodName" => "Dialogues",
          "path" => "/",
          "body" => "none",
          "responseBody" => "dialogue",
          "method" => "GET",
          "additionalBindings" => [
            %{
              "path" => "/scifi/dialogues",
              "method" => "GET",
              "body" => "none",
              "responseBody" => "dialogue"
            }
          ]
        }
      ]
    },
    "expose" => %{
      "method" => "none",
      "ingress" => %{
        "className" => "none",
        "host" => "none",
        "path" => "/",
        "useTls" => true,
        "tls" => %{
          "secretName" => "eigr-functions-tls",
          "certManager" => %{
            "clusterIssuer" => "none",
            "temporaryCertificate" => "false",
            "commonName" => "none",
            "duration" => "2h",
            "renew-before" => "1h",
            "usages" => [],
            "http01IngressClass" => "none",
            "http01EditInPlace" => "false"
          }
        }
      },
      "loadBalancer" => %{
        "port" => 8080,
        "targetPort" => 9000
      },
      "nodePort" => %{
        "port" => 8080,
        "targetPort" => 9000,
        "nodePort" => 30001
      }
    },
    "autoscaler" => %{
      "strategy" => "hpa",
      "minReplicas" => 1,
      "maxReplicas" => 100,
      "averageCpuUtilizationPercentage" => 80,
      "averageMemoryUtilizationValue" => "100Mi"
    },
    "portBinding" => %{
      "port" => 8080,
      "type" => "grpc",
      "socketPath" => "/var/run/eigr/functions.sock"
    },
    "resources" => %{
      "limits" => %{"cpu" => "100m", "memory" => "100Mi"},
      "requests" => %{"cpu" => "100m", "memory" => "100Mi"}
    }
  }

  def get_function_manifests(%{
        "apiVersion" => "functions.eigr.io/v1",
        "kind" => "Function",
        "metadata" => %{
          "name" => name
        },
        "spec" => %{"backend" => params}
      }) do
    backend_params = Map.merge(@default_params, params)

    definition =
      Map.get(backend_params, "expose")
      |> Map.get("method")
      |> case do
        "ingress" ->
          {:ingress, Ingress.manifest("default", name, backend_params)}

        "loadbalancer" ->
          {:load_balancer, LoadBalancer.manifest("default", name, backend_params)}

        "nodeport" ->
          {:node_port, NodePort.manifest("default", name, backend_params)}

        _ ->
          {:none, %{}}
      end

    %{
      name: name,
      namespace: "default",
      configmap: ConfigMap.manifest("default", name, backend_params),
      deployment: Deployment.manifest("default", name, backend_params),
      autoscaler: HPA.manifest("default", name, backend_params),
      app_service: ClusterIPService.manifest("default", name, backend_params),
      cluster_service: HeadlessService.manifest("default", name, backend_params),
      expose_service: definition
    }
  end

  def get_function_manifests(%{
        "apiVersion" => "functions.eigr.io/v1",
        "kind" => "Function",
        "metadata" => %{
          "name" => name,
          "namespace" => ns
        },
        "spec" => %{"backend" => params}
      }) do
    backend_params = Map.merge(@default_params, params)

    definition =
      Map.get(backend_params, "expose")
      |> Map.get("method")
      |> case do
        "ingress" ->
          {:ingress, Ingress.manifest(ns, name, backend_params)}

        "loadbalancer" ->
          {:load_balancer, LoadBalancer.manifest(ns, name, backend_params)}

        "nodeport" ->
          {:node_port, NodePort.manifest(ns, name, backend_params)}

        _ ->
          {:none, %{}}
      end

    %{
      name: name,
      namespace: ns,
      configmap: ConfigMap.manifest(ns, name, backend_params),
      deployment: Deployment.manifest(ns, name, backend_params),
      autoscaler: HPA.manifest(ns, name, backend_params),
      app_service: ClusterIPService.manifest(ns, name, backend_params),
      cluster_service: HeadlessService.manifest(ns, name, backend_params),
      expose_service: definition
    }
  end
end
