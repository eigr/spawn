defmodule Operator.K8S.Limits do
  @moduledoc false

  @generic_lang_resources_limits %{
    "limits" => %{"cpu" => "500m", "memory" => "512Mi"},
    "requests" => %{"cpu" => "100m", "memory" => "100Mi"}
  }

  @go_lang_resources_limits %{
    "limits" => %{"cpu" => "500m", "memory" => "1024Mi"},
    "requests" => %{"cpu" => "200m", "memory" => "70Mi"}
  }

  @java_lang_resources_limits %{
    "limits" => %{"cpu" => "500m", "memory" => "2048Mi"},
    "requests" => %{"cpu" => "200m", "memory" => "100Mi"}
  }

  @python_lang_resources_limits %{
    "limits" => %{"cpu" => "500m", "memory" => "512Mi"},
    "requests" => %{"cpu" => "100m", "memory" => "70Mi"}
  }

  def get_limits(resources, "go"), do: Map.merge(@go_lang_resources_limits, resources)
  def get_limits(resources, "java"), do: Map.merge(@java_lang_resources_limits, resources)
  def get_limits(resources, "none"), do: Map.merge(@generic_lang_resources_limits, resources)
  def get_limits(resources, "python"), do: Map.merge(@python_lang_resources_limits, resources)
  def get_limits(resources, _), do: Map.merge(@generic_lang_resources_limits, resources)
end
