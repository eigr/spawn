defmodule SpawnSdk.Context do
  defstruct state: nil, caller: nil, self: nil, metadata: nil

  @type t :: %__MODULE__{
          state: term(),
          caller: term(),
          self: term(),
          metadata: map()
        }
end
