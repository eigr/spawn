defmodule SpawnOperator.K8s.System.Namespace do
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
      "apiVersion" => "v1",
      "kind" => "Namespace",
      "metadata" => %{
        "labels" => %{
          "system-name" => "system-#{name}",
          "spawn-eigr.io/controller.version" =>
            "#{to_string(Application.spec(:spawn_operator, :vsn))}"
        },
        "name" => String.downcase(name)
      }
    }
  end
end
