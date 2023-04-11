defmodule SpawnOperator.FactoryTest do
  @moduledoc false

  def build_embedded_actor_host(attrs \\ []) do
    %{
      "apiVersion" => "spawn-eigr.io/v1",
      "kind" => "ActorHost",
      "metadata" => %{
        "name" => attrs[:name] || "spawn-test",
        "system" => "spawn-system",
        "namespace" => "default",
        "generation" => 1
      },
      "spec" => %{
        "host" => %{
          "embedded" => true,
          "image" => attrs[:host_image] || "eigr/spawn-test:latest"
        }
      }
    }
  end

  def build_embedded_actor_host_with_volume_mounts(attrs \\ []) do
    %{
      "apiVersion" => "spawn-eigr.io/v1",
      "kind" => "ActorHost",
      "metadata" => %{
        "name" => attrs[:name] || "spawn-test",
        "system" => "spawn-system",
        "namespace" => "default",
        "generation" => 1
      },
      "spec" => %{
        "host" => %{
          "embedded" => true,
          "image" => attrs[:host_image] || "eigr/spawn-test:latest",
          "volumeMounts" => [
            %{
              "mountPath" => "/home/example",
              "name" => "volume-name"
            }
          ]
        },
        "volumes" => [
          %{
            "name" => "volume-name",
            "emptyDir" => "{}"
          }
        ]
      }
    }
  end

  def build_simple_actor_host(attrs \\ []) do
    %{
      "apiVersion" => "spawn-eigr.io/v1",
      "kind" => "ActorHost",
      "metadata" => %{
        "name" => attrs[:name] || "spawn-test",
        "system" => "spawn-system",
        "namespace" => "default",
        "generation" => 1
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
        "namespace" => "default",
        "generation" => 1
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

  def build_simple_actor_host_with_volume_mounts(attrs \\ []) do
    %{
      "apiVersion" => "spawn-eigr.io/v1",
      "kind" => "ActorHost",
      "metadata" => %{
        "name" => attrs[:name] || "spawn-test",
        "system" => "spawn-system",
        "namespace" => "default",
        "generation" => 1
      },
      "spec" => %{
        "host" => %{
          "image" => attrs[:host_image] || "eigr/spawn-test:latest",
          "volumeMounts" => [
            %{
              "mountPath" => "/home/example",
              "name" => "volume-name"
            }
          ]
        },
        "volumes" => [
          %{
            "name" => "volume-name",
            "emptyDir" => "{}"
          }
        ]
      }
    }
  end
end
