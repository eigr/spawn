defmodule Eigr.Functions.Protocol.Actors.StateManager do
  require Logger

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorState}

  @spec load(String.t(), Eigr.Functions.Protocol.Actors.Actor.t()) :: {:ok, any}
  def load(_name, %Actor{} = actor) do
    {:ok, actor.actor_state}
  end

  @spec save(String.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
  def save(name, %ActorState{} = state) do
    Logger.debug("Saving state for actor #{name}")

    {:ok, state}
  end
end
