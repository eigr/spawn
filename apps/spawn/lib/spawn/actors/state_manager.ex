defmodule Eigr.Functions.Protocol.Actors.StateManager do
  require Logger

  alias Eigr.Functions.Protocol.Actors.ActorState
  alias Statestores.Schemas.Event
  alias Statestores.Manager.StateManager, as: StateStoreManager

  @spec load(String.t()) :: {:ok, any}
  def load(name) do
    case StateStoreManager.load(name) do
      %Event{actor: name, revision: rev, tags: tags, data_type: type, data: data} = event ->
        {:ok,
         ActorState.new(tags: tags, state: Google.Protobuf.Any.new(type_url: type, value: data))}

      _ ->
        {:not_found, %{}}
    end
  end

  @spec save(String.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
  def save(_name, nil), do: {:ok, nil}

  def save(_name, %ActorState{state: actor_state} = state)
      when is_nil(actor_state) or actor_state == %{},
      do: {:ok, %{}}

  def save(name, %ActorState{tags: tags, state: actor_state} = state) do
    Logger.debug("Saving state for actor #{name}")

    %Event{
      actor: name,
      revision: 0,
      tags: tags,
      data_type: actor_state.type_url,
      data: actor_state.value
    }
    |> StateStoreManager.save()

    {:ok, state}
  end

  @spec save_async(String.t(), Eigr.Functions.Protocol.Actors.ActorState.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.ActorState.t()}
  def save_async(_name, nil), do: {:ok, %{}}

  def save_async(_name, %ActorState{state: actor_state} = state)
      when is_nil(actor_state) or actor_state == %{},
      do: {:ok, %{}}

  def save_async(name, %ActorState{tags: tags, state: actor_state} = state) do
    spawn(fn ->
      Logger.debug("Saving state for actor #{name}")

      %Event{
        actor: name,
        revision: 0,
        tags: tags,
        data_type: actor_state.type_url,
        data: actor_state.value
      }
      |> StateStoreManager.save()
    end)

    {:ok, state}
  end
end
