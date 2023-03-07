defmodule SpawnOperator.Handler.ActivatorHandler do
  @moduledoc """
  `ActivatorHandler` handles Activator CRD events
  """

  @behaviour Pluggable

  @impl Pluggable
  def init(_opts), do: nil

  @impl Pluggable
  def call(%Bonny.Axn{action: action, resource: resource} = axn, nil)
      when action in [:add, :modify] do
    args = SpawnOperator.get_args(resource)

    axn
    |> Bonny.Axn.register_descendant(build_service(args))
    |> Bonny.Axn.register_descendant(build_config_map(args))
    |> Bonny.Axn.register_descendant(build_resource(args))
    |> Bonny.Axn.register_descendant(build_cron_job(args))
    # |> Bonny.Axn.update_status(fn status ->
    #  put_in(status, [Access.key(:some, %{}), :field], "foo")
    # end)
    |> Bonny.Axn.success_event()
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:reconcile] do
    # TODO: Reconcile hpa for rebalancing Nodes
    # TODO: Recreate resources if not exists
    Bonny.Axn.success_event(axn)
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:delete] do
    Bonny.Axn.success_event(axn)
  end

  defp build_service(args) do
  end

  defp build_config_map(args) do
  end

  defp build_resource(args) do
  end

  defp build_cron_job(args) do
  end
end
