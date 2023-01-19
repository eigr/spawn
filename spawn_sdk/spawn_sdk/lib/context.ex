defmodule SpawnSdk.Context do
  defstruct state: nil, caller: nil, self: nil, metadata: nil, tags: nil

  @type t :: %__MODULE__{
          state: term(),
          caller: term(),
          self: term(),
          metadata: map(),
          tags: map()
        }
end
