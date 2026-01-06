defmodule Actors.Registry.HostActor do
  @moduledoc """
  `HostActor` Defines the type of Actor that will be registered in `ActorRegistry`.
  """

  alias Spawn.Actors.ActorId

  defstruct actor_id: nil, node: nil, opts: nil

  @type t :: %__MODULE__{
          node: node(),
          actor_id: ActorId.t(),
          opts: Keyword.t()
        }
end
