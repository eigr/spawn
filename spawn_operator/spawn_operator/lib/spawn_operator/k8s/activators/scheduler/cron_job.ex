defmodule SpawnOperator.K8s.Activators.Scheduler.CronJob do
  @moduledoc false

  @behaviour SpawnOperator.K8s.Manifest

  @activator_cli_version "0.1.0"

  @impl true
  def manifest(resource, _opts \\ []) do
    Enum.map(resource.params["bindings"]["sources"], fn source ->
      %{"name" => name, "expr" => expr} = source

      sinks =
        Enum.filter(resource.params["bindings"]["sinks"], fn sink ->
          Enum.find(sink["binding"], fn %{"name" => binding_name} -> binding_name == name end)
        end)
        |> Enum.map(fn sink ->
          %{
            "name" => sink["name"],
            "image" => "eigr/spawn-activator-cli:#{@activator_cli_version}",
            "imagePullPolicy" => "IfNotPresent",
            "command" => [
              "./activator-cli",
              "#{sink["system"]}",
              "#{sink["actor"]}",
              "#{sink["command"]}"
            ]
          }
        end)

      %{
        "apiVersion" => "batch/v1",
        "kind" => "CronJob",
        "metadata" => %{
          "name" => "#{name}-cron-job",
          "namespace" => resource.namespace
        },
        "spec" => %{
          "schedule" => expr,
          "jobTemplate" => %{
            "spec" => %{
              "template" => %{
                "spec" => %{
                  "containers" => sinks,
                  "restartPolicy" => "OnFailure"
                }
              }
            }
          }
        }
      }
    end)
  end
end
