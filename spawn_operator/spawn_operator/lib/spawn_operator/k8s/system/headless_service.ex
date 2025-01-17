defmodule SpawnOperator.K8s.System.HeadlessService do
  @moduledoc false
  @behaviour SpawnOperator.K8s.Manifest

  @ports [
    %{"name" => "epmd", "protocol" => "TCP", "port" => 4369, "targetPort" => "epmd"}
  ]

  @impl true
  def manifest(
        %{
          system: _system,
          namespace: _ns,
          name: name,
          params: _params,
          labels: _labels,
          annotations: _annotations
        } = _resource,
        _opts \\ []
      ) do
    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "svc-cluster-name" => "system-#{name}",
          "spawn-eigr.io/controller.version" =>
            "#{to_string(Application.spec(:spawn_operator, :vsn))}"
        },
        "name" => "system-#{name}",
        "namespace" => String.downcase(name)
      },
      "spec" => %{
        "clusterIP" => "None",
        "selector" => %{"actor-system" => name},
        "ports" => @ports
      }
    }
  end
end
