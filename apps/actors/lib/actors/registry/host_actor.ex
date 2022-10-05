defmodule Actors.Registry.HostActor do
  alias Eigr.Functions.Protocol.Actors.Actor

  defstruct actor: nil, node: nil, opts: nil

  @type t :: %__MODULE__{
          node: pid(),
          actor: Actor.t(),
          opts: Keyword.t()
        }
end
