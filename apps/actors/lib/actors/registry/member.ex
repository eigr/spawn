defmodule Actors.Registry.Member do
  alias Actors.Registry.HostActor

  defstruct id: nil, host_function: nil

  @type t :: %__MODULE__{
          id: pid(),
          host_function: HostActor.t()
        }
end
