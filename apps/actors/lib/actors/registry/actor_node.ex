defmodule Actors.Registry.ActorNode do
  @moduledoc """
  `ActorNode`
  """
  alias Eigr.Functions.Protocol.Actors.Actor

  defstruct actors: nil, opts: nil

  @type t :: %__MODULE__{
          actors: list(Actor.t()),
          opts: Keyword.t()
        }
end
