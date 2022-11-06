defmodule SpawnOperator.FactoryTest do
  @moduledoc false

  def build_simple_actor_host(attrs \\ []) do
    %{
      "apiVersion" => "spawn-eigr.io/v1",
      "kind" => "ActorHost",
      "metadata" => %{
        "name" => attrs[:name] || "spawn-test",
        "system" => "spawn-system",
        "namespace" => "default"
      },
      "spec" => %{
        "host" => %{
          "image" => attrs[:host_image] || "eigr/spawn-test:latest"
        }
      }
    }
  end

  def build_simple_actor_host_with_ports(attrs \\ []) do
    %{
      "apiVersion" => "spawn-eigr.io/v1",
      "kind" => "ActorHost",
      "metadata" => %{
        "name" => attrs[:name] || "spawn-test",
        "namespace" => "default"
      },
      "spec" => %{
        "host" => %{
          "image" => attrs[:host_image] || "eigr/spawn-test:latest",
          "ports" => [
            %{"containerPort" => attrs[:http] || 8090, "name" => "http"},
            %{"containerPort" => attrs[:https] || 8091, "name" => "https"}
          ]
        }
      }
    }
  end
end
