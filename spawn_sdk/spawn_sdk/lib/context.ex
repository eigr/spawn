defmodule SpawnSdk.Context do
  defstruct state: nil, caller: nil, self: nil

  @type t :: %__MODULE__{
          state: term(),
          caller: term(),
          self: term()
        }
end
