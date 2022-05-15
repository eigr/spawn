defmodule Eigr.Functions.Protocol.ProxyInfo do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          protocol_major_version: integer,
          protocol_minor_version: integer,
          proxy_name: String.t(),
          proxy_version: String.t()
        }
  defstruct [:protocol_major_version, :protocol_minor_version, :proxy_name, :proxy_version]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 9, 80, 114, 111, 120, 121, 73, 110, 102, 111, 18, 52, 10, 22, 112, 114, 111, 116, 111,
        99, 111, 108, 95, 109, 97, 106, 111, 114, 95, 118, 101, 114, 115, 105, 111, 110, 24, 1,
        32, 1, 40, 5, 82, 20, 112, 114, 111, 116, 111, 99, 111, 108, 77, 97, 106, 111, 114, 86,
        101, 114, 115, 105, 111, 110, 18, 52, 10, 22, 112, 114, 111, 116, 111, 99, 111, 108, 95,
        109, 105, 110, 111, 114, 95, 118, 101, 114, 115, 105, 111, 110, 24, 2, 32, 1, 40, 5, 82,
        20, 112, 114, 111, 116, 111, 99, 111, 108, 77, 105, 110, 111, 114, 86, 101, 114, 115, 105,
        111, 110, 18, 29, 10, 10, 112, 114, 111, 120, 121, 95, 110, 97, 109, 101, 24, 3, 32, 1,
        40, 9, 82, 9, 112, 114, 111, 120, 121, 78, 97, 109, 101, 18, 35, 10, 13, 112, 114, 111,
        120, 121, 95, 118, 101, 114, 115, 105, 111, 110, 24, 4, 32, 1, 40, 9, 82, 12, 112, 114,
        111, 120, 121, 86, 101, 114, 115, 105, 111, 110>>
    )
  end

  field :protocol_major_version, 1, type: :int32
  field :protocol_minor_version, 2, type: :int32
  field :proxy_name, 3, type: :string
  field :proxy_version, 4, type: :string
end

defmodule Eigr.Functions.Protocol.ServiceInfo do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          service_name: String.t(),
          service_version: String.t(),
          service_runtime: String.t(),
          support_library_name: String.t(),
          support_library_version: String.t(),
          protocol_major_version: integer,
          protocol_minor_version: integer
        }
  defstruct [
    :service_name,
    :service_version,
    :service_runtime,
    :support_library_name,
    :support_library_version,
    :protocol_major_version,
    :protocol_minor_version
  ]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 11, 83, 101, 114, 118, 105, 99, 101, 73, 110, 102, 111, 18, 33, 10, 12, 115, 101, 114,
        118, 105, 99, 101, 95, 110, 97, 109, 101, 24, 1, 32, 1, 40, 9, 82, 11, 115, 101, 114, 118,
        105, 99, 101, 78, 97, 109, 101, 18, 39, 10, 15, 115, 101, 114, 118, 105, 99, 101, 95, 118,
        101, 114, 115, 105, 111, 110, 24, 2, 32, 1, 40, 9, 82, 14, 115, 101, 114, 118, 105, 99,
        101, 86, 101, 114, 115, 105, 111, 110, 18, 39, 10, 15, 115, 101, 114, 118, 105, 99, 101,
        95, 114, 117, 110, 116, 105, 109, 101, 24, 3, 32, 1, 40, 9, 82, 14, 115, 101, 114, 118,
        105, 99, 101, 82, 117, 110, 116, 105, 109, 101, 18, 48, 10, 20, 115, 117, 112, 112, 111,
        114, 116, 95, 108, 105, 98, 114, 97, 114, 121, 95, 110, 97, 109, 101, 24, 4, 32, 1, 40, 9,
        82, 18, 115, 117, 112, 112, 111, 114, 116, 76, 105, 98, 114, 97, 114, 121, 78, 97, 109,
        101, 18, 54, 10, 23, 115, 117, 112, 112, 111, 114, 116, 95, 108, 105, 98, 114, 97, 114,
        121, 95, 118, 101, 114, 115, 105, 111, 110, 24, 5, 32, 1, 40, 9, 82, 21, 115, 117, 112,
        112, 111, 114, 116, 76, 105, 98, 114, 97, 114, 121, 86, 101, 114, 115, 105, 111, 110, 18,
        52, 10, 22, 112, 114, 111, 116, 111, 99, 111, 108, 95, 109, 97, 106, 111, 114, 95, 118,
        101, 114, 115, 105, 111, 110, 24, 6, 32, 1, 40, 5, 82, 20, 112, 114, 111, 116, 111, 99,
        111, 108, 77, 97, 106, 111, 114, 86, 101, 114, 115, 105, 111, 110, 18, 52, 10, 22, 112,
        114, 111, 116, 111, 99, 111, 108, 95, 109, 105, 110, 111, 114, 95, 118, 101, 114, 115,
        105, 111, 110, 24, 7, 32, 1, 40, 5, 82, 20, 112, 114, 111, 116, 111, 99, 111, 108, 77,
        105, 110, 111, 114, 86, 101, 114, 115, 105, 111, 110>>
    )
  end

  field :service_name, 1, type: :string
  field :service_version, 2, type: :string
  field :service_runtime, 3, type: :string
  field :support_library_name, 4, type: :string
  field :support_library_version, 5, type: :string
  field :protocol_major_version, 6, type: :int32
  field :protocol_minor_version, 7, type: :int32
end

defmodule Eigr.Functions.Protocol.Init do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          proxy_info: Eigr.Functions.Protocol.ProxyInfo.t() | nil
        }
  defstruct [:proxy_info]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 4, 73, 110, 105, 116, 18, 65, 10, 10, 112, 114, 111, 120, 121, 95, 105, 110, 102, 111,
        24, 1, 32, 1, 40, 11, 50, 34, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105,
        111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 80, 114, 111, 120, 121, 73,
        110, 102, 111, 82, 9, 112, 114, 111, 120, 121, 73, 110, 102, 111>>
    )
  end

  field :proxy_info, 1, type: Eigr.Functions.Protocol.ProxyInfo
end

defmodule Eigr.Functions.Protocol.InitResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          service_info: Eigr.Functions.Protocol.ServiceInfo.t() | nil,
          actors: [Eigr.Functions.Protocol.Actors.Actor.t()]
        }
  defstruct [:service_info, :actors]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 12, 73, 110, 105, 116, 82, 101, 115, 112, 111, 110, 115, 101, 18, 71, 10, 12, 115,
        101, 114, 118, 105, 99, 101, 95, 105, 110, 102, 111, 24, 1, 32, 1, 40, 11, 50, 36, 46,
        101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111,
        116, 111, 99, 111, 108, 46, 83, 101, 114, 118, 105, 99, 101, 73, 110, 102, 111, 82, 11,
        115, 101, 114, 118, 105, 99, 101, 73, 110, 102, 111, 18, 61, 10, 6, 97, 99, 116, 111, 114,
        115, 24, 2, 32, 3, 40, 11, 50, 37, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116,
        105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114,
        115, 46, 65, 99, 116, 111, 114, 82, 6, 97, 99, 116, 111, 114, 115>>
    )
  end

  field :service_info, 1, type: Eigr.Functions.Protocol.ServiceInfo
  field :actors, 2, repeated: true, type: Eigr.Functions.Protocol.Actors.Actor
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
