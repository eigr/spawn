defmodule Actors.Actor.Interface do
  @moduledoc """
  `Invoker` is responsible for making calls to the Host Function
  """

  alias Actors.Actor.Entity.EntityState
  alias Eigr.Functions.Protocol.ActorInvocation

  @type state :: EntityState.t()
  @type payload :: ActorInvocation.t()
  @type default_methods :: []

  @callback invoke_host(any(), state(), default_methods()) ::
              {:ok, any(), state()} | {:error, any(), state()}

  defmacro __using__(_opts) do
    quote do
      @behaviour Actors.Actor.Interface

      defp invoke_host(payload, state) do
        {:ok, nil, state}
      end

      defoverridable Actors.Actor.Interface
    end
  end
end
