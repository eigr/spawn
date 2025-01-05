defmodule Actors.Actor.Entity.Lifecycle.ProjectionConsumers do
  @moduledoc """
  We register projections linked to this process instead of the actor entity process
  so that the deactivation of the actor entity does not affect the projection consumers.
  """

  use GenServer

  alias Actors.Actor.Entity.Lifecycle.StreamConsumer

  def init(opts) do
    {:ok, opts}
  end

  def handle_call({:init_consumer, actor_opts}, _from, state) do
    response = StreamConsumer.start_link(actor_opts)

    {:reply, response, state}
  end

  def new(actor_opts) do
    GenServer.call(__MODULE__, {:init_consumer, actor_opts})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
end
