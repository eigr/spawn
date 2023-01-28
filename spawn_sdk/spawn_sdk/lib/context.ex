defmodule SpawnSdk.Context do
  @moduledoc """
  The context is responsible for sending the State information as well as its metadata
  to the Actor and the Proxy and vice versa.
  """
  defstruct state: nil, caller: nil, self: nil, metadata: nil, tags: nil

  @type t :: %__MODULE__{
          state: term(),
          caller: term(),
          self: term(),
          metadata: map(),
          tags: map()
        }
end
