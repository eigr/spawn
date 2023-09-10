defmodule SpawnOperator.K8s.Activators.Rabbitmq do
  @moduledoc """
  Create RabbitMQ Activator resources
  """

  alias SpawnOperator.K8s.Activators.Rabbitmq.{
    Cm.Configmap,
    DaemonSet,
    Deployment,
    Service
  }

  import Spawn.Utils.Common, only: [to_existing_atom_or_new: 1]

  @spec apply(map(), Bonny.Axn.t(), atom()) :: Bonny.Axn.t()
  def apply(%{params: spec} = args, axn, action) when action in [:add, :modify] do
    resources =
      case get_activator_kind(spec) do
        :daemonset ->
          [Configmap.manifest(args), DaemonSet.manifest(args), Service.manifest(args)]

        :deployment ->
          [Configmap.manifest(args), Deployment.manifest(args), Service.manifest(args)]

        nil ->
          []

        _ ->
          raise ArgumentError, "Invalid Activator Kind. Valids are [DaemonSet, Deployment]"
      end

    axn
    |> register(resources)
    |> Bonny.Axn.success_event()
  end

  def apply(_args, axn, action) when action in [:reconcile] do
    Bonny.Axn.success_event(axn)
  end

  def apply(_args, axn, action) when action in [:delete], do: Bonny.Axn.success_event(axn)

  defp register(axn, resources),
    do: Enum.reduce(resources, axn, &Bonny.Axn.register_descendant(&2, &1))

  defp get_activator_kind(%{"activator" => %{"kind" => kind}}) do
    kind |> String.downcase() |> to_existing_atom_or_new()
  end

  defp get_activator_kind(_), do: :daemonset
end
