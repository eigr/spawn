defmodule SpawnOperator.Handler.ActivatorHandler do
  @moduledoc """
  `ActivatorHandler` handles Activator CRD events
  """

  @behaviour Pluggable

  @impl Pluggable
  def init(_opts), do: nil

  @impl Pluggable
  def call(axn, nil) do
    axn
  end
end
