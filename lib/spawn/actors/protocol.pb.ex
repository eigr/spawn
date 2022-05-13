defmodule Eigr.Functions.Protocol.Init do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(<<10, 4, 73, 110, 105, 116>>)
  end
end

defmodule Eigr.Functions.Protocol.InitResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode("\n\fInitResponse")
  end
end

defmodule Eigr.Functions.Protocol.Create do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          actor: Eigr.Functions.Protocol.Actors.Actor.t() | nil
        }
  defstruct [:actor]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 6, 67, 114, 101, 97, 116, 101, 18, 59, 10, 5, 97, 99, 116, 111, 114, 24, 1, 32, 1, 40,
        11, 50, 37, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46,
        112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115, 46, 65, 99, 116,
        111, 114, 82, 5, 97, 99, 116, 111, 114>>
    )
  end

  field :actor, 1, type: Eigr.Functions.Protocol.Actors.Actor
end

defmodule Eigr.Functions.Protocol.Call do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          command_name: String.t(),
          value: Google.Protobuf.Any.t() | nil,
          actor: Eigr.Functions.Protocol.Actors.Actor.t() | nil
        }
  defstruct [:command_name, :value, :actor]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 4, 67, 97, 108, 108, 18, 33, 10, 12, 99, 111, 109, 109, 97, 110, 100, 95, 110, 97,
        109, 101, 24, 1, 32, 1, 40, 9, 82, 11, 99, 111, 109, 109, 97, 110, 100, 78, 97, 109, 101,
        18, 42, 10, 5, 118, 97, 108, 117, 101, 24, 2, 32, 1, 40, 11, 50, 20, 46, 103, 111, 111,
        103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 65, 110, 121, 82, 5, 118,
        97, 108, 117, 101, 18, 59, 10, 5, 97, 99, 116, 111, 114, 24, 3, 32, 1, 40, 11, 50, 37, 46,
        101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111,
        116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115, 46, 65, 99, 116, 111, 114, 82, 5,
        97, 99, 116, 111, 114>>
    )
  end

  field :command_name, 1, type: :string
  field :value, 2, type: Google.Protobuf.Any
  field :actor, 3, type: Eigr.Functions.Protocol.Actors.Actor
end

defmodule Eigr.Functions.Protocol.CallResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          value: Google.Protobuf.Any.t() | nil,
          actor: Eigr.Functions.Protocol.Actors.Actor.t() | nil
        }
  defstruct [:value, :actor]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 12, 67, 97, 108, 108, 82, 101, 115, 112, 111, 110, 115, 101, 18, 42, 10, 5, 118, 97,
        108, 117, 101, 24, 1, 32, 1, 40, 11, 50, 20, 46, 103, 111, 111, 103, 108, 101, 46, 112,
        114, 111, 116, 111, 98, 117, 102, 46, 65, 110, 121, 82, 5, 118, 97, 108, 117, 101, 18, 59,
        10, 5, 97, 99, 116, 111, 114, 24, 2, 32, 1, 40, 11, 50, 37, 46, 101, 105, 103, 114, 46,
        102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46,
        97, 99, 116, 111, 114, 115, 46, 65, 99, 116, 111, 114, 82, 5, 97, 99, 116, 111, 114>>
    )
  end

  field :value, 1, type: Google.Protobuf.Any
  field :actor, 2, type: Eigr.Functions.Protocol.Actors.Actor
end

defmodule Eigr.Functions.Protocol.Cast do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          command_name: String.t(),
          value: Google.Protobuf.Any.t() | nil,
          actor: Eigr.Functions.Protocol.Actors.Actor.t() | nil
        }
  defstruct [:command_name, :value, :actor]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 4, 67, 97, 115, 116, 18, 33, 10, 12, 99, 111, 109, 109, 97, 110, 100, 95, 110, 97,
        109, 101, 24, 1, 32, 1, 40, 9, 82, 11, 99, 111, 109, 109, 97, 110, 100, 78, 97, 109, 101,
        18, 42, 10, 5, 118, 97, 108, 117, 101, 24, 2, 32, 1, 40, 11, 50, 20, 46, 103, 111, 111,
        103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 65, 110, 121, 82, 5, 118,
        97, 108, 117, 101, 18, 59, 10, 5, 97, 99, 116, 111, 114, 24, 3, 32, 1, 40, 11, 50, 37, 46,
        101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111,
        116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115, 46, 65, 99, 116, 111, 114, 82, 5,
        97, 99, 116, 111, 114>>
    )
  end

  field :command_name, 1, type: :string
  field :value, 2, type: Google.Protobuf.Any
  field :actor, 3, type: Eigr.Functions.Protocol.Actors.Actor
end

defmodule Eigr.Functions.Protocol.CastResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          actor: Eigr.Functions.Protocol.Actors.Actor.t() | nil
        }
  defstruct [:actor]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 12, 67, 97, 115, 116, 82, 101, 115, 112, 111, 110, 115, 101, 18, 59, 10, 5, 97, 99,
        116, 111, 114, 24, 1, 32, 1, 40, 11, 50, 37, 46, 101, 105, 103, 114, 46, 102, 117, 110,
        99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99, 116,
        111, 114, 115, 46, 65, 99, 116, 111, 114, 82, 5, 97, 99, 116, 111, 114>>
    )
  end

  field :actor, 1, type: Eigr.Functions.Protocol.Actors.Actor
end

defmodule Eigr.Functions.Protocol.ActorProxyRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          message: {atom, any}
        }
  defstruct [:message]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 17, 65, 99, 116, 111, 114, 80, 114, 111, 120, 121, 82, 101, 113, 117, 101, 115, 116,
        18, 51, 10, 4, 105, 110, 105, 116, 24, 1, 32, 1, 40, 11, 50, 29, 46, 101, 105, 103, 114,
        46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108,
        46, 73, 110, 105, 116, 72, 0, 82, 4, 105, 110, 105, 116, 18, 51, 10, 4, 99, 97, 108, 108,
        24, 2, 32, 1, 40, 11, 50, 29, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105,
        111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 67, 97, 108, 108, 72, 0, 82,
        4, 99, 97, 108, 108, 18, 51, 10, 4, 99, 97, 115, 116, 24, 3, 32, 1, 40, 11, 50, 29, 46,
        101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111,
        116, 111, 99, 111, 108, 46, 67, 97, 115, 116, 72, 0, 82, 4, 99, 97, 115, 116, 66, 9, 10,
        7, 109, 101, 115, 115, 97, 103, 101>>
    )
  end

  oneof :message, 0
  field :init, 1, type: Eigr.Functions.Protocol.Init, oneof: 0
  field :call, 2, type: Eigr.Functions.Protocol.Call, oneof: 0
  field :cast, 3, type: Eigr.Functions.Protocol.Cast, oneof: 0
end

defmodule Eigr.Functions.Protocol.ActorProxyResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          message: {atom, any}
        }
  defstruct [:message]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 18, 65, 99, 116, 111, 114, 80, 114, 111, 120, 121, 82, 101, 115, 112, 111, 110, 115,
        101, 18, 76, 10, 13, 105, 110, 105, 116, 95, 114, 101, 115, 112, 111, 110, 115, 101, 24,
        1, 32, 1, 40, 11, 50, 37, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111,
        110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 73, 110, 105, 116, 82, 101, 115,
        112, 111, 110, 115, 101, 72, 0, 82, 12, 105, 110, 105, 116, 82, 101, 115, 112, 111, 110,
        115, 101, 18, 68, 10, 12, 99, 114, 101, 97, 116, 101, 95, 97, 99, 116, 111, 114, 24, 2,
        32, 1, 40, 11, 50, 31, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110,
        115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 67, 114, 101, 97, 116, 101, 72, 0, 82,
        11, 99, 114, 101, 97, 116, 101, 65, 99, 116, 111, 114, 18, 76, 10, 13, 99, 97, 108, 108,
        95, 114, 101, 115, 112, 111, 110, 115, 101, 24, 3, 32, 1, 40, 11, 50, 37, 46, 101, 105,
        103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99,
        111, 108, 46, 67, 97, 108, 108, 82, 101, 115, 112, 111, 110, 115, 101, 72, 0, 82, 12, 99,
        97, 108, 108, 82, 101, 115, 112, 111, 110, 115, 101, 18, 76, 10, 13, 99, 97, 115, 116, 95,
        114, 101, 115, 112, 111, 110, 115, 101, 24, 4, 32, 1, 40, 11, 50, 37, 46, 101, 105, 103,
        114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111,
        108, 46, 67, 97, 115, 116, 82, 101, 115, 112, 111, 110, 115, 101, 72, 0, 82, 12, 99, 97,
        115, 116, 82, 101, 115, 112, 111, 110, 115, 101, 66, 9, 10, 7, 109, 101, 115, 115, 97,
        103, 101>>
    )
  end

  oneof :message, 0
  field :init_response, 1, type: Eigr.Functions.Protocol.InitResponse, oneof: 0
  field :create_actor, 2, type: Eigr.Functions.Protocol.Create, oneof: 0
  field :call_response, 3, type: Eigr.Functions.Protocol.CallResponse, oneof: 0
  field :cast_response, 4, type: Eigr.Functions.Protocol.CastResponse, oneof: 0
end

defmodule Eigr.Functions.Protocol.ActorService.Service do
  @moduledoc false
  use GRPC.Service, name: "eigr.functions.protocol.ActorService"

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.ServiceDescriptorProto.decode(
      <<10, 12, 65, 99, 116, 111, 114, 83, 101, 114, 118, 105, 99, 101, 18, 100, 10, 5, 83, 112,
        97, 119, 110, 18, 42, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110,
        115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 65, 99, 116, 111, 114, 80, 114, 111,
        120, 121, 82, 101, 113, 117, 101, 115, 116, 26, 43, 46, 101, 105, 103, 114, 46, 102, 117,
        110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 65, 99,
        116, 111, 114, 80, 114, 111, 120, 121, 82, 101, 115, 112, 111, 110, 115, 101, 40, 1, 48,
        1>>
    )
  end

  rpc :Spawn,
      stream(Eigr.Functions.Protocol.ActorProxyRequest),
      stream(Eigr.Functions.Protocol.ActorProxyResponse)
end

defmodule Eigr.Functions.Protocol.ActorService.Stub do
  @moduledoc false
  use GRPC.Stub, service: Eigr.Functions.Protocol.ActorService.Service
end
