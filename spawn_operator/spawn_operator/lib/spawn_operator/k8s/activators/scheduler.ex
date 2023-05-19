defmodule SpawnOperator.K8s.Activators.Scheduler do
  @moduledoc """
  Create Simple Activator resources

  To create a Scheduler you must define similarly to this:

  ```
  ---
  apiVersion: spawn-eigr.io/v1
  kind: Activator
  metadata:
    name: cron-activator # Mandatory. Name of the activator
    namespace: default # Optional. Default namespace is "default"
    annotations:
      # Mandatory. Name of the ActorSystem declared in ActorSystem CRD
      spawn-eigr.io/actor-system: spawn-system
  spec:
    activator:
      type: Cron
      kind: Deployment # DaemonSet
    bindings:
      sources:
        - name: joe-scheduler
          expr: "* * * * *"
        - name: robert-scheduler
          expr: "* * * * *"
      sinks:
        - name: joe-sink
          actor: joe # Name of an Actor
          action: setLanguage # Name of an Actor Action to call
          binding:
            - name: robert-scheduler
        - name: robert-sink
          actor: robert
          action: setLanguage
          binding:
            - name: robert-scheduler
   ```
  """
  alias SpawnOperator.K8s.Activators.Scheduler.{
    Cm.Configmap,
    CronJob,
    DaemonSet,
    DaemonSetService,
    Deployment,
    DeploymentService
  }

  import Spawn.Utils.Common, only: [to_existing_atom_or_new: 1]

  @spec apply(map(), Bonny.Axn.t(), atom()) :: Bonny.Axn.t()
  def apply(args, axn, action) when action in [:add, :modify] do
    cron_job_manifests = CronJob.manifest(args)
    configmap = Configmap.manifest(args)

    {resource, service} =
      case get_activator_kind(args.params) do
        :daemonset ->
          {
            DaemonSet.manifest(args),
            DaemonSetService.manifest(args)
          }

        :deployment ->
          {
            Deployment.manifest(args),
            DeploymentService.manifest(args)
          }

        nil -> {%{}, %{}}

        _ ->
          raise ArgumentError, "Invalid Activator Kind. Valids are [DaemonSet, Deployment]"
      end

    axn
    # |> Bonny.Axn.register_descendant(configmap)
    # |> Bonny.Axn.register_descendant(service)
    # |> Bonny.Axn.register_descendant(resource)
    |> register_multiple_cronjobs(cron_job_manifests)
    |> Bonny.Axn.success_event()
  end

  def apply(_args, axn, action) when action in [:reconcile] do
    Bonny.Axn.success_event(axn)
  end

  def apply(_args, axn, action) when action in [:delete], do: Bonny.Axn.success_event(axn)

  defp register_multiple_cronjobs(axn, manifests) do
    Enum.reduce(manifests, axn, & Bonny.Axn.register_descendant(&2, &1))
  end

  defp get_activator_kind(%{"activator" => %{"kind" => kind}}) do
    kind |> String.downcase() |> to_existing_atom_or_new()
  end

  defp get_activator_kind(_), do: nil
end
