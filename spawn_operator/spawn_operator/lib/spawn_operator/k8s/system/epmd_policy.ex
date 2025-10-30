defmodule SpawnOperator.K8s.System.EpmdPolicy do
  @moduledoc false
  @behaviour SpawnOperator.K8s.Manifest

  @port 4369

  @impl true
  def manifest(%{labels: labels} = _resource, _opts \\ []) do
    %{
      "apiVersion" => "networking.k8s.io/v1",
      "kind" => "NetworkPolicy",
      "metadata" => %{
        "name" => "spawn-epmd-policy",
        "namespace" => "eigr-functions",
        "labels" =>
          Map.merge(labels, %{
            "spawn-eigr.io/controller.version" => "#{Application.spec(:spawn_operator, :vsn)}"
          })
      },
      "spec" => %{
        "podSelector" => %{
          "matchLabels" => %{
            "app" => "epmd",
            "epmd-cluster" => "spawn-epmd"
          }
        },
        "policyTypes" => ["Ingress"],
        "ingress" => [
          %{
            "from" => [
              %{
                "podSelector" => %{
                  "matchLabels" => %{
                    "operator" => "spawn-operator"
                  }
                }
              }
            ],
            "ports" => [
              %{
                "protocol" => "TCP",
                "port" => @port
              }
            ]
          }
        ]
      }
    }
  end
end
