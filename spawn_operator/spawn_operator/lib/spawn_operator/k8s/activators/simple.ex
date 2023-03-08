defmodule SpawnOperator.K8s.Activators.Simple do
  @moduledoc """
  Create Simple Activator resources
  """

  @spec apply(map(), Bonny.Axn.t(), atom()) :: Bonny.Axn.t()
  def apply(args, axn, action) when action in [:add, :modify] do
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

  def apply(args, axn, action) when action in [:reconcile] do
    Bonny.Axn.success_event(axn)
  end

  def apply(args, axn, action) when action in [:delete], do: Bonny.Axn.success_event(axn)

  defp build_service(args) do
  end

  defp build_config_map(args) do
  end

  defp build_resource(args) do
  end

  defp build_cron_job(args) do
  end
end
