defmodule SpawnSdk.Context do
  defstruct state: nil

  @type t :: %__MODULE__{
          state: module()
        }
end
