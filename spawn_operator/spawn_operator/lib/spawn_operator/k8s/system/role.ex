defmodule SpawnOperator.K8s.System.Role do
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
      "kind" => "Role",
      "metadata" => %{
        "labels" => %{
          "system-name" => "system-#{name}",
          "spawn-eigr.io/controller.version" =>
            "#{to_string(Application.spec(:spawn_operator, :vsn))}"
        },
        "name" => "#{name}-role",
        "namespace" => String.downcase(name)
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps", "secrets"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["pods"],
          "verbs" => ["create", "delete", "get", "list", "patch"]
        }
      ]
    }
  end
end
