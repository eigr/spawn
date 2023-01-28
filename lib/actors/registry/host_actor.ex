defmodule Actors.Registry.HostActor do
  @moduledoc """
  `HostActor` Defines the type of Actor that will be registered in `ActorRegistry`.
  """

  alias Eigr.Functions.Protocol.Actors.Actor

  defstruct actor: nil, node: nil, opts: nil

  @type t :: %__MODULE__{
          node: pid(),
          actor: Actor.t(),
          opts: Keyword.t()
        }
end
