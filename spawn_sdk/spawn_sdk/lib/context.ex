defmodule SpawnSdk.Context do
  defstruct [:state, :from, :self]

  @type t :: %__MODULE__{
          state: term(),
          from: term(),
          self: term()
        }
end
