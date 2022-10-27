defmodule SpawnOperator.Handler.ActorSystemHandler do
  @moduledoc """
  `ActorSystemHandler` handles ActorSystem CRD events
  """
  defmacro __using__(_) do
    quote do
      import SpawnOperator,
        only: [
          build_actor_system: 1,
          track_event: 2
        ]

      @impl true
      def add(resource) do
        track_event(:add, resource)
        build_actor_system(resource)
        :ok
      end

      @impl true
      def modify(resource) do
        track_event(:modify, resource)
        build_actor_system(resource)
        :ok
      end

      @impl true
      def delete(resource) do
        track_event(:delete, resource)
        :ok
      end

      @impl true
      def reconcile(resource) do
        track_event(:reconcile, resource)
        :ok
      end
    end
  end
end
