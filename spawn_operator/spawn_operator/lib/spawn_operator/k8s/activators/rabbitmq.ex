defmodule SpawnOperator.K8s.Activators.Rabbitmq do
  @moduledoc """
  Create RabbitMQ Activator resources
  """

  @spec apply(map(), Bonny.Axn.t(), atom()) :: Bonny.Axn.t()
  def apply(args, axn, action) when action in [:add, :modify] do
    Bonny.Axn.success_event(axn)
  end

  def apply(args, axn, action) when action in [:reconcile] do
    Bonny.Axn.success_event(axn)
  end

  def apply(args, axn, action) when action in [:delete], do: Bonny.Axn.success_event(axn)
end
