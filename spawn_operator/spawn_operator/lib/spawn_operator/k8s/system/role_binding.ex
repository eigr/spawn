defmodule SpawnOperator.K8s.System.RoleBinding do
  @moduledoc false
  @behaviour SpawnOperator.K8s.Manifest

  @impl true
  def manifest(
        %{
          system: _system,
          namespace: ns,
          name: name,
          params: _params,
          labels: _labels,
          annotations: _annotations
        } = _resource,
        _opts \\ []
      ) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "labels" => %{
          "system-name" => "system-#{name}",
          "spawn-eigr.io/controller.version" =>
            "#{to_string(Application.spec(:spawn_operator, :vsn))}"
        },
        "name" => "#{name}-rolebinding",
        "namespace" => String.downcase(name)
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => "#{name}-role"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "#{name}-sa",
          "namespace" => String.downcase(name)
        }
      ]
    }
  end
end
