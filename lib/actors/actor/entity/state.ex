defmodule Actors.Actor.Entity.EntityState do
  @moduledoc """
  `EntityState` Represents the internal state of an Actor.
  """
  alias Eigr.Functions.Protocol.Actors.Actor

  defstruct system: nil, actor: nil, state_hash: nil, revision: 0, opts: []

  @type t :: %__MODULE__{
          system: String.t(),
          actor: Actor.t(),
          state_hash: binary(),
          revision: number(),
          projection_stream_pid: pid(),
          opts: Keyword.t()
        }

  def unpack(%__MODULE__{actor: %Actor{}} = state) do
    state
  end

  def unpack(state) do
    %{state | actor: Actor.decode(state.actor)}
  end

  def pack(%__MODULE__{actor: %Actor{}} = state) do
    %{state | actor: Actor.encode(state.actor)}
  end

  def pack(state) do
    state
  end
end
