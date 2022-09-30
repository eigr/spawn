defmodule Actors.Registry.Member do
  alias Actors.Registry.Host

  defstruct id: nil, host_function: nil

  @type t :: %__MODULE__{
          id: pid(),
          host_function: Host.t()
        }
end
