defmodule SpawnOperator.K8s.System.EpmdDS do
  @moduledoc false
  @behaviour SpawnOperator.K8s.Manifest

  @ports [
    %{"name" => "epmd", "containerPort" => 4369, "hostPort" => 4369, "protocol" => "TCP"}
  ]

  @impl true
  def manifest(%{labels: labels} = _resource, _opts \\ []) do
    %{
      "apiVersion" => "apps/v1",
      "kind" => "DaemonSet",
      "metadata" => %{
        "name" => "spawn-epmd",
        "namespace" => "eigr-functions",
        "labels" =>
          Map.merge(labels, %{
            "app" => "spawn-epmd",
            "spawn-eigr.io/controller.version" => "#{Application.spec(:spawn_operator, :vsn)}"
          })
      },
      "spec" => %{
        "selector" => %{
          "matchLabels" => %{
            "app" => "epmd",
            "epmd-cluster" => "spawn-epmd"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app" => "epmd",
              "epmd-cluster" => "spawn-epmd"
            }
          },
          "spec" => %{
            "hostNetwork" => true,
            "containers" => [
              %{
                "name" => "epmd",
                "image" => "erlang:26",
                "command" => ["epmd", "-d", "-relaxed_command_check"],
                "ports" => @ports,
                "resources" => %{
                  "limits" => %{
                    "memory" => "10Mi",
                    "cpu" => "10m"
                  },
                  "requests" => %{
                    "memory" => "5Mi",
                    "cpu" => "5m"
                  }
                }
              }
            ]
          }
        }
      }
    }
  end
end
