defmodule Actors.Actor.Entity.EntityState do
  alias Eigr.Functions.Protocol.Actors.Actor

  defstruct system: nil, actor: nil, state_hash: nil, opts: []

  @type t :: %__MODULE__{
          system: String.t(),
          actor: Actor.t(),
          state_hash: binary(),
          opts: Keyword.t()
        }
end
