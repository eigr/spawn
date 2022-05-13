defmodule Eigr.Functions.Protocol.Actors.ActorState do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          state: Google.Protobuf.Any.t() | nil
        }
  defstruct [:state]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 10, 65, 99, 116, 111, 114, 83, 116, 97, 116, 101, 18, 42, 10, 5, 115, 116, 97, 116,
        101, 24, 1, 32, 1, 40, 11, 50, 20, 46, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111,
        116, 111, 98, 117, 102, 46, 65, 110, 121, 82, 5, 115, 116, 97, 116, 101>>
    )
  end

  field :state, 1, type: Google.Protobuf.Any
end

defmodule Eigr.Functions.Protocol.Actors.Actor do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          actor_state: Eigr.Functions.Protocol.Actors.ActorState.t() | nil
        }
  defstruct [:name, :actor_state]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 5, 65, 99, 116, 111, 114, 18, 18, 10, 4, 110, 97, 109, 101, 24, 1, 32, 1, 40, 9, 82,
        4, 110, 97, 109, 101, 18, 75, 10, 11, 97, 99, 116, 111, 114, 95, 115, 116, 97, 116, 101,
        24, 2, 32, 1, 40, 11, 50, 42, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105,
        111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115,
        46, 65, 99, 116, 111, 114, 83, 116, 97, 116, 101, 82, 10, 97, 99, 116, 111, 114, 83, 116,
        97, 116, 101>>
    )
  end

  field :name, 1, type: :string
  field :actor_state, 2, type: Eigr.Functions.Protocol.Actors.ActorState
end
