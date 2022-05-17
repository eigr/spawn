defmodule Eigr.Functions.Protocol.Actors.Registry.ActorsEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: Eigr.Functions.Protocol.Actors.Actor.t() | nil
        }
  defstruct [:key, :value]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 11, 65, 99, 116, 111, 114, 115, 69, 110, 116, 114, 121, 18, 16, 10, 3, 107, 101, 121,
        24, 1, 32, 1, 40, 9, 82, 3, 107, 101, 121, 18, 59, 10, 5, 118, 97, 108, 117, 101, 24, 2,
        32, 1, 40, 11, 50, 37, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110,
        115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115, 46, 65,
        99, 116, 111, 114, 82, 5, 118, 97, 108, 117, 101, 58, 8, 8, 0, 16, 0, 24, 0, 56, 1>>
    )
  end

  field :key, 1, type: :string
  field :value, 2, type: Eigr.Functions.Protocol.Actors.Actor
end

defmodule Eigr.Functions.Protocol.Actors.Registry do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          actors: %{String.t() => Eigr.Functions.Protocol.Actors.Actor.t() | nil}
        }
  defstruct [:actors]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 8, 82, 101, 103, 105, 115, 116, 114, 121, 18, 76, 10, 6, 97, 99, 116, 111, 114, 115,
        24, 1, 32, 3, 40, 11, 50, 52, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105,
        111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115,
        46, 82, 101, 103, 105, 115, 116, 114, 121, 46, 65, 99, 116, 111, 114, 115, 69, 110, 116,
        114, 121, 82, 6, 97, 99, 116, 111, 114, 115, 26, 102, 10, 11, 65, 99, 116, 111, 114, 115,
        69, 110, 116, 114, 121, 18, 16, 10, 3, 107, 101, 121, 24, 1, 32, 1, 40, 9, 82, 3, 107,
        101, 121, 18, 59, 10, 5, 118, 97, 108, 117, 101, 24, 2, 32, 1, 40, 11, 50, 37, 46, 101,
        105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116,
        111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115, 46, 65, 99, 116, 111, 114, 82, 5, 118,
        97, 108, 117, 101, 58, 8, 8, 0, 16, 0, 24, 0, 56, 1>>
    )
  end

  field :actors, 1,
    repeated: true,
    type: Eigr.Functions.Protocol.Actors.Registry.ActorsEntry,
    map: true
end

defmodule Eigr.Functions.Protocol.Actors.ActorSystem do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          name: String.t(),
          registry: Eigr.Functions.Protocol.Actors.Registry.t() | nil
        }
  defstruct [:name, :registry]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 11, 65, 99, 116, 111, 114, 83, 121, 115, 116, 101, 109, 18, 18, 10, 4, 110, 97, 109,
        101, 24, 1, 32, 1, 40, 9, 82, 4, 110, 97, 109, 101, 18, 68, 10, 8, 114, 101, 103, 105,
        115, 116, 114, 121, 24, 2, 32, 1, 40, 11, 50, 40, 46, 101, 105, 103, 114, 46, 102, 117,
        110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99,
        116, 111, 114, 115, 46, 82, 101, 103, 105, 115, 116, 114, 121, 82, 8, 114, 101, 103, 105,
        115, 116, 114, 121>>
    )
  end

  field :name, 1, type: :string
  field :registry, 2, type: Eigr.Functions.Protocol.Actors.Registry
end

defmodule Eigr.Functions.Protocol.Actors.ActorSnapshotStrategy do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          strategy: {atom, any}
        }
  defstruct [:strategy]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 21, 65, 99, 116, 111, 114, 83, 110, 97, 112, 115, 104, 111, 116, 83, 116, 114, 97,
        116, 101, 103, 121, 18, 75, 10, 7, 116, 105, 109, 101, 111, 117, 116, 24, 1, 32, 1, 40,
        11, 50, 47, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46,
        112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115, 46, 84, 105, 109,
        101, 111, 117, 116, 83, 116, 114, 97, 116, 101, 103, 121, 72, 0, 82, 7, 116, 105, 109,
        101, 111, 117, 116, 66, 10, 10, 8, 115, 116, 114, 97, 116, 101, 103, 121>>
    )
  end

  oneof :strategy, 0
  field :timeout, 1, type: Eigr.Functions.Protocol.Actors.TimeoutStrategy, oneof: 0
end

defmodule Eigr.Functions.Protocol.Actors.ActorDeactivateStrategy do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          strategy: {atom, any}
        }
  defstruct [:strategy]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 23, 65, 99, 116, 111, 114, 68, 101, 97, 99, 116, 105, 118, 97, 116, 101, 83, 116, 114,
        97, 116, 101, 103, 121, 18, 75, 10, 7, 116, 105, 109, 101, 111, 117, 116, 24, 1, 32, 1,
        40, 11, 50, 47, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115,
        46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115, 46, 84, 105,
        109, 101, 111, 117, 116, 83, 116, 114, 97, 116, 101, 103, 121, 72, 0, 82, 7, 116, 105,
        109, 101, 111, 117, 116, 66, 10, 10, 8, 115, 116, 114, 97, 116, 101, 103, 121>>
    )
  end

  oneof :strategy, 0
  field :timeout, 1, type: Eigr.Functions.Protocol.Actors.TimeoutStrategy, oneof: 0
end

defmodule Eigr.Functions.Protocol.Actors.TimeoutStrategy do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          timeout: integer
        }
  defstruct [:timeout]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 15, 84, 105, 109, 101, 111, 117, 116, 83, 116, 114, 97, 116, 101, 103, 121, 18, 24,
        10, 7, 116, 105, 109, 101, 111, 117, 116, 24, 1, 32, 1, 40, 3, 82, 7, 116, 105, 109, 101,
        111, 117, 116>>
    )
  end

  field :timeout, 1, type: :int64
end

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
          actorSystem: Eigr.Functions.Protocol.Actors.ActorSystem.t() | nil,
          actor_state: Eigr.Functions.Protocol.Actors.ActorState.t() | nil,
          snapshot_strategy: Eigr.Functions.Protocol.Actors.ActorSnapshotStrategy.t() | nil,
          deactivate_strategy: Eigr.Functions.Protocol.Actors.ActorDeactivateStrategy.t() | nil
        }
  defstruct [:name, :actorSystem, :actor_state, :snapshot_strategy, :deactivate_strategy]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 5, 65, 99, 116, 111, 114, 18, 18, 10, 4, 110, 97, 109, 101, 24, 1, 32, 1, 40, 9, 82,
        4, 110, 97, 109, 101, 18, 77, 10, 11, 97, 99, 116, 111, 114, 83, 121, 115, 116, 101, 109,
        24, 2, 32, 1, 40, 11, 50, 43, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105,
        111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115,
        46, 65, 99, 116, 111, 114, 83, 121, 115, 116, 101, 109, 82, 11, 97, 99, 116, 111, 114, 83,
        121, 115, 116, 101, 109, 18, 75, 10, 11, 97, 99, 116, 111, 114, 95, 115, 116, 97, 116,
        101, 24, 3, 32, 1, 40, 11, 50, 42, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116,
        105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114,
        115, 46, 65, 99, 116, 111, 114, 83, 116, 97, 116, 101, 82, 10, 97, 99, 116, 111, 114, 83,
        116, 97, 116, 101, 18, 98, 10, 17, 115, 110, 97, 112, 115, 104, 111, 116, 95, 115, 116,
        114, 97, 116, 101, 103, 121, 24, 4, 32, 1, 40, 11, 50, 53, 46, 101, 105, 103, 114, 46,
        102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46,
        97, 99, 116, 111, 114, 115, 46, 65, 99, 116, 111, 114, 83, 110, 97, 112, 115, 104, 111,
        116, 83, 116, 114, 97, 116, 101, 103, 121, 82, 16, 115, 110, 97, 112, 115, 104, 111, 116,
        83, 116, 114, 97, 116, 101, 103, 121, 18, 104, 10, 19, 100, 101, 97, 99, 116, 105, 118,
        97, 116, 101, 95, 115, 116, 114, 97, 116, 101, 103, 121, 24, 5, 32, 1, 40, 11, 50, 55, 46,
        101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111,
        116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115, 46, 65, 99, 116, 111, 114, 68,
        101, 97, 99, 116, 105, 118, 97, 116, 101, 83, 116, 114, 97, 116, 101, 103, 121, 82, 18,
        100, 101, 97, 99, 116, 105, 118, 97, 116, 101, 83, 116, 114, 97, 116, 101, 103, 121>>
    )
  end

  field :name, 1, type: :string
  field :actorSystem, 2, type: Eigr.Functions.Protocol.Actors.ActorSystem
  field :actor_state, 3, type: Eigr.Functions.Protocol.Actors.ActorState
  field :snapshot_strategy, 4, type: Eigr.Functions.Protocol.Actors.ActorSnapshotStrategy
  field :deactivate_strategy, 5, type: Eigr.Functions.Protocol.Actors.ActorDeactivateStrategy
end
