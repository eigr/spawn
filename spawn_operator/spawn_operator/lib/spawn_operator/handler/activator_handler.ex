defmodule SpawnOperator.Handler.ActivatorHandler do
  @moduledoc """
  `ActivatorHandler` handles Activator CRD events
  """
  alias SpawnOperator.K8s.Activators.Activator

  @behaviour Pluggable

  @impl Pluggable
  def init(_opts), do: nil

  @impl Pluggable
  def call(%Bonny.Axn{action: action, resource: resource} = axn, nil),
    do:
      SpawnOperator.get_args(resource)
      |> Activator.apply(axn, action)
end
