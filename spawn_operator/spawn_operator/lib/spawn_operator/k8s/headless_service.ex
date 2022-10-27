defmodule SpawnOperator.K8s.HeadlessService do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def(manifest(system, ns, name, params),
    do: %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "svc-cluster-name" => "system-#{system}-svc",
          "spawn-eigr.io/controller.version" =>
            "#{to_string(Application.spec(:spawn_operator, :vsn))}"
        },
        "name" => "system-#{system}-svc",
        "namespace" => ns
      },
      "spec" => %{
        "clusterIP" => "None",
        "selector" => %{"cluster-name" => system},
        "ports" => [
          %{"port" => 4369, "name" => "epmd"}
        ]
      }
    }
  )
end
