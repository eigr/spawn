defmodule Actors.Registry.Cluster do
  alias Actors.Registry.Member

  defstruct members: nil

  @type t :: %__MODULE__{
          members: list(Member.t())
        }
end
