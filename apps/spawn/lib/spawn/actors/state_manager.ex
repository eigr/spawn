defmodule Eigr.Functions.Protocol.Actors.StateManager do
  require Logger

  alias Eigr.Functions.Protocol.Actors.ActorState

  @spec load(String.t()) :: {:ok, any}
  def load(_name) do
    {:ok, %ActorState{}}
  end

  @spec save(String.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
  def save(_name, nil), do: {:ok, nil}

  def save(name, %ActorState{} = state) do
    Logger.debug("Saving state for actor #{name}")

    {:ok, state}
  end

  @spec save_async(String.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
  def save_async(_name, nil), do: {:ok, nil}

  def save_async(name, %ActorState{} = state) do
    Logger.debug("Saving state for actor #{name}")

    {:ok, state}
  end
end
