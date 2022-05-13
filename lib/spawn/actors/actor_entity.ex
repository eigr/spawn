defmodule Eigr.Functions.Protocol.Actors.ActorEntity do
  use GenServer

  alias Eigr.Functions.Protocol.Actors.{Actor, ActorState, StateManager}

  @spec init(Eigr.Functions.Protocol.Actors.Actor.t()) ::
          {:ok, Eigr.Functions.Protocol.Actors.Actor.t(), {:continue, :load_state}}
  def init(%Actor{} = state) do
    Process.flag(:trap_exit, true)
    {:ok, state, {:continue, :load_state}}
  end

  @spec handle_continue(:load_state, Eigr.Functions.Protocol.Actors.Actor.t()) ::
          {:noreply, Eigr.Functions.Protocol.Actors.Actor.t()}
  def handle_continue(:load_state, %Actor{actor_state: %ActorState{} = actor_state} = state) do
    updated_state = actor_state
    {:noreply, %Actor{state | actor_state: updated_state}}
  end

  def terminate(_reason, %Actor{name: name, actor_state: %ActorState{} = actor_state} = _state),
    do: StateManager.save(name, actor_state)
end
