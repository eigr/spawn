defmodule Operator.Controllers.V1.ActorNode do
  @doc """
  Operator.Controllers.V1.Node

  ### Examples
  ```yaml
  ---
  apiVersion: spawn.eigr.io/v1
  kind: ActorNode
  metadata:
    name: actors-system-test # Mandatory. Name of the actor system
    # The namespace where the function will be deployed to the cluster.
    # All proxies deployed in a given namespace form a cluster, that is, they are visible to each other.
    namespace: default # Optional. Default namespace is "default"
  spec:
    function:
      image: eigr/spawn-springboot-examples:latest # Mandatory
  """
  use Bonny.Controller
  require Logger

  alias Operator.K8S.Controller, as: K8SController

  @group "spawn.eigr.io"

  @version "v1"

  @rule {"apps", ["deployments"], ["*"]}
  @rule {"", ["services", "pods", "configmaps"], ["*"]}
  @rule {"autoscaling", ["horizontalpodautoscalers"], ["*"]}
  @rule {"extensions", ["ingresses", "ingressclasses"], ["*"]}
  @rule {"networking.k8s.io", ["ingresses", "ingressclasses"], ["*"]}

  @scope :cluster
  @names %{
    plural: "actornodes",
    singular: "actornode",
    kind: "ActorNode",
    shortNames: [
      "ac",
      "actor",
      "actors",
      "actornode",
      "actornodes"
    ]
  }

  @additional_printer_columns []

  @doc """
  Called periodically for each existing CustomResource to allow for reconciliation.
  """
  @spec reconcile(map()) :: :ok | :error
  @impl Bonny.Controller
  def reconcile(payload) do
    track_event(:reconcile, payload)
    :ok
  end

  @doc """
  Creates a kubernetes `deployment`, `service` and `configmap` that runs a "Eigr" app.
  """
  @spec add(map()) :: :ok | :error
  @impl Bonny.Controller
  def add(payload) do
    track_event(:add, payload)
    resources = K8SController.get_function_manifests(payload)

    with {:ok, _} <- K8s.Client.create(resources.app_service) |> run(),
         {:ok, _} <- K8s.Client.create(resources.configmap) |> run(),
         {:ok, _} <- K8s.Client.create(resources.autoscaler) |> run() do
      resource_res = K8s.Client.create(resources.deployment) |> run()

      case K8s.Client.create(resources.cluster_service) |> run() do
        {:ok, _} ->
          Logger.info("Cluster service created")

        {:error, err} ->
          Logger.warning(
            "Failure creating cluster service: #{inspect(err)}. Probably already exists."
          )
      end

      result =
        case resource_res do
          {:ok, _} ->
            case resources.expose_service do
              {:ingress, definition} ->
                K8s.Client.create(definition) |> run()

              {:load_balancer, definition} ->
                Logger.warning(
                  "Using LoadBalancer is extremely discouraged. Instead try using the Ingress method"
                )

                K8s.Client.create(definition) |> run()

              {:node_port, definition} ->
                Logger.warning(
                  "Using NodePort is extremely discouraged. Instead try using the Ingress method"
                )

                K8s.Client.create(definition) |> run()

              {:none, _} ->
                {:ok, nil}
            end

          {:error, error} ->
            {:error, error}
        end

      case result do
        {:ok, _} ->
          Logger.info(
            "User function #{resources.name} has been successfully deployed to namespace #{resources.namespace}"
          )

          :ok

        {:error, error} ->
          Logger.error(
            "One or more resources of user function #{resources.name} failed during deployment. Error: #{inspect(error)}"
          )

          {:error, error}
      end
    else
      {:error, error} ->
        Logger.error(
          "One or more resources of user function #{resources.name} failed during deployment. Error: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  @doc """
  Updates `deployment`, `service` and `configmap` resources.
  """
  @spec modify(map()) :: :ok | :error
  @impl Bonny.Controller
  def modify(payload) do
    resources = K8SController.get_function_manifests(payload)

    with {:ok, _} <- K8s.Client.delete(resources.app_service) |> run(),
         {:ok, _} <- K8s.Client.create(resources.app_service) |> run(),
         {:ok, _} <- K8s.Client.patch(resources.cluster_service) |> run(),
         {:ok, _} <- K8s.Client.patch(resources.autoscaler) |> run(),
         {:ok, _} <- K8s.Client.patch(resources.configmap) |> run() do
      resource_res = K8s.Client.patch(resources.deployment) |> run()

      result =
        case resource_res do
          {:ok, _} ->
            case resources.expose_service do
              {:ingress, definition} ->
                K8s.Client.patch(definition) |> run()

              {:load_balancer, definition} ->
                Logger.warning(
                  "Using LoadBalancer is extremely discouraged. Instead try using the Ingress method"
                )

                K8s.Client.patch(definition) |> run()

              {:node_port, definition} ->
                Logger.warning(
                  "Using NodePort is extremely discouraged. Instead try using the Ingress method"
                )

                K8s.Client.patch(definition) |> run()

              {:none, _} ->
                {:ok, nil}
            end

          {:error, error} ->
            {:error, error}
        end

      case result do
        {:ok, _} ->
          Logger.info(
            "User function #{resources.name} has been successfully updated to namespace #{resources.namespace}"
          )

          :ok

        {:error, error} ->
          Logger.error(
            "One or more resources of user function #{resources.name} failed during updating. Error: #{inspect(error)}"
          )

          {:error, error}
      end
    else
      {:error, error} ->
        Logger.error(
          "One or more resources of user function #{resources.name} failed during updating. Error: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  @doc """
  Deletes `deployment`, `service` and `configmap` resources.
  """
  @spec delete(map()) :: :ok | :error
  @impl Bonny.Controller
  def delete(payload) do
    track_event(:delete, payload)
    resources = K8SController.get_function_manifests(payload)

    with {:ok, _} <- K8s.Client.delete(resources.app_service) |> run(),
         {:ok, _} <- K8s.Client.delete(resources.cluster_service) |> run(),
         {:ok, _} <- K8s.Client.delete(resources.autoscaler) |> run(),
         {:ok, _} <- K8s.Client.delete(resources.configmap) |> run() do
      resource_res = K8s.Client.delete(resources.deployment) |> run()

      result =
        case resource_res do
          {:ok, _} ->
            case resources.expose_service do
              {:ingress, definition} ->
                K8s.Client.delete(definition) |> run()

              {:load_balancer, definition} ->
                K8s.Client.delete(definition) |> run()

              {:node_port, definition} ->
                K8s.Client.delete(definition) |> run()

              {:none, _} ->
                {:ok, nil}
            end
        end

      case result do
        {:ok, _} ->
          Logger.info(
            "All resources for user function #{resources.name} have been successfully deleted from namespace #{resources.namespace}"
          )

          :ok

        {:error, error} ->
          Logger.error(
            "One or more resources of the user role #{resources.name} failed during its removal. Error: #{inspect(error)}"
          )

          {:error, error}
      end
    else
      {:error, error} ->
        Logger.error(
          "One or more resources of the user role #{resources.name} failed during its removal. Error: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  defp run(%K8s.Operation{} = op),
    do: K8s.Client.run(op, Bonny.Config.cluster_name())

  defp track_event(type, resource),
    do: Logger.info("#{type}: #{inspect(resource)}")
end
