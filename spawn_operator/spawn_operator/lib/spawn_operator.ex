defmodule SpawnOperator do
  @moduledoc """
  Documentation for `SpawnOperator`.
  """
  require Logger

  alias SpawnOperator.K8s.{
    Deployment,
    ConfigMap.ActivatorCM,
    ConfigMap.ActorSystemCM,
    ConfigMap.SidecarCM
  }

  import Bonny.Config, only: [conn: 0]
  import Bonny.Resource, only: [add_owner_reference: 2]

  @doc """
  ---
  apiVersion: spawn-eigr.io/v1
  kind: ActorHost
  metadata:
    name: my-node-app # Mandatory. Name of the Node containing Actor Host Functions
    system: my-actor-system # mandatory. Name of the ActorSystem declared in ActorSystem CRD
    namespace: default # Optional. Default namespace is "default"
  spec:
    function:
      image: eigr/spawn-springboot-examples:latest # Mandatory
      ports:
      - containerPort: 80

  """
  def build_actor_host_deployment(resource) do
    host_resource = build_host_deploy(resource)
    host_config_map = build_host_configmap(resource)

    case apply_resource(resource, [host_config_map, host_resource]) do
      :ok ->
        {:ok, "Actor Host Function created suscessfully"}

      error ->
        {:error, "Failure to create Actor Host Function. Cause #{inspect(error)}"}
    end
  end

  defp build_host_deploy(resource) do
    %{system: system, namespace: ns, name: name, params: params} = get_args(resource)
    Deployment.manifest(system, ns, name, params)
  end

  defp build_host_configmap(resource) do
    %{system: system, namespace: ns, name: name, params: params} = get_args(resource)
    SidecarCM.manifest(system, ns, name, params)
  end

  defp get_args(resource) do
    metadata = Map.fetch!(resource, "metadata")

    ns = Map.get(metadata, "namespace", "default")
    name = Map.fetch!(metadata, "name")
    system = Map.get(metadata, "system", "spawn-system")
    params = Map.get(resource, "spec")

    %{system: system, namespace: ns, name: name, params: params}
  end

  defp apply_resource(crd, resources) when is_list(resources) do
    resources
    |> Enum.each(fn resource ->
      Logger.debug("Applying resource #{inspect(resource)}")
      apply_resource(crd, resource)
    end)
  end

  defp apply_resource(crd, resource) when is_map(resource) do
    crd
    |> add_owner_reference(resource)
    |> IO.inspect()
    |> K8s.Client.create()
    |> then(&K8s.Client.run(conn(), &1))
  end

  def track_event(type, resource),
    do: Logger.info("#{type}: #{inspect(resource)}")
end
