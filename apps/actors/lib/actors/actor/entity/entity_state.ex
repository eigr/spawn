defmodule Actors.Actor.Entity.EntityState do
  alias Eigr.Functions.Protocol.Actors.Actor

  defstruct actor: nil, state_hash: nil

  @type t(actor, state_hash) :: %__MODULE__{
          actor: actor,
          state_hash: state_hash
        }

  @type t :: %__MODULE__{actor: Actor.t(), state_hash: binary()}
end
