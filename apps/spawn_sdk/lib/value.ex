defmodule SpawnSdk.Value do
  defstruct state: nil, value: nil

  @type t :: %__MODULE__{
          state: module(),
          value: module()
        }
end
