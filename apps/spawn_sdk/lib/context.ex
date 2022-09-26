defmodule SpawnSdk.Context do
  defstruct state: nil, value: nil

  @type t :: %__MODULE__{
          state: module()
        }
end
