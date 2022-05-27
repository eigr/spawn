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

  field(:protocol_major_version, 1, type: :int32)
  field(:protocol_minor_version, 2, type: :int32)
  field(:proxy_name, 3, type: :string)
  field(:proxy_version, 4, type: :string)
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

  field(:service_name, 1, type: :string)
  field(:service_version, 2, type: :string)
  field(:service_runtime, 3, type: :string)
  field(:support_library_name, 4, type: :string)
  field(:support_library_version, 5, type: :string)
  field(:protocol_major_version, 6, type: :int32)
  field(:protocol_minor_version, 7, type: :int32)
end

defmodule Eigr.Functions.Protocol.RegistrationRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          service_info: Eigr.Functions.Protocol.ServiceInfo.t() | nil,
          actor_system: Eigr.Functions.Protocol.Actors.ActorSystem.t() | nil
        }
  defstruct [:service_info, :actor_system]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 19, 82, 101, 103, 105, 115, 116, 114, 97, 116, 105, 111, 110, 82, 101, 113, 117, 101,
        115, 116, 18, 71, 10, 12, 115, 101, 114, 118, 105, 99, 101, 95, 105, 110, 102, 111, 24, 1,
        32, 1, 40, 11, 50, 36, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110,
        115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 83, 101, 114, 118, 105, 99, 101, 73,
        110, 102, 111, 82, 11, 115, 101, 114, 118, 105, 99, 101, 73, 110, 102, 111, 18, 78, 10,
        12, 97, 99, 116, 111, 114, 95, 115, 121, 115, 116, 101, 109, 24, 2, 32, 1, 40, 11, 50, 43,
        46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111,
        116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115, 46, 65, 99, 116, 111, 114, 83,
        121, 115, 116, 101, 109, 82, 11, 97, 99, 116, 111, 114, 83, 121, 115, 116, 101, 109>>
    )
  end

  field(:service_info, 1, type: Eigr.Functions.Protocol.ServiceInfo)
  field(:actor_system, 2, type: Eigr.Functions.Protocol.Actors.ActorSystem)
end

defmodule Eigr.Functions.Protocol.RegistrationResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          proxy_info: Eigr.Functions.Protocol.ProxyInfo.t() | nil
        }
  defstruct [:proxy_info]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 20, 82, 101, 103, 105, 115, 116, 114, 97, 116, 105, 111, 110, 82, 101, 115, 112, 111,
        110, 115, 101, 18, 65, 10, 10, 112, 114, 111, 120, 121, 95, 105, 110, 102, 111, 24, 1, 32,
        1, 40, 11, 50, 34, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115,
        46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 80, 114, 111, 120, 121, 73, 110, 102, 111,
        82, 9, 112, 114, 111, 120, 121, 73, 110, 102, 111>>
    )
  end

  field(:proxy_info, 1, type: Eigr.Functions.Protocol.ProxyInfo)
end

defmodule Eigr.Functions.Protocol.InvocationRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          actor: Eigr.Functions.Protocol.Actors.Actor.t() | nil,
          command_name: String.t(),
          value: Google.Protobuf.Any.t() | nil,
          async: boolean
        }
  defstruct [:actor, :command_name, :value, :async]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 17, 73, 110, 118, 111, 99, 97, 116, 105, 111, 110, 82, 101, 113, 117, 101, 115, 116,
        18, 59, 10, 5, 97, 99, 116, 111, 114, 24, 1, 32, 1, 40, 11, 50, 37, 46, 101, 105, 103,
        114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111,
        108, 46, 97, 99, 116, 111, 114, 115, 46, 65, 99, 116, 111, 114, 82, 5, 97, 99, 116, 111,
        114, 18, 33, 10, 12, 99, 111, 109, 109, 97, 110, 100, 95, 110, 97, 109, 101, 24, 2, 32, 1,
        40, 9, 82, 11, 99, 111, 109, 109, 97, 110, 100, 78, 97, 109, 101, 18, 42, 10, 5, 118, 97,
        108, 117, 101, 24, 3, 32, 1, 40, 11, 50, 20, 46, 103, 111, 111, 103, 108, 101, 46, 112,
        114, 111, 116, 111, 98, 117, 102, 46, 65, 110, 121, 82, 5, 118, 97, 108, 117, 101, 18, 20,
        10, 5, 97, 115, 121, 110, 99, 24, 4, 32, 1, 40, 8, 82, 5, 97, 115, 121, 110, 99>>
    )
  end

  field(:actor, 1, type: Eigr.Functions.Protocol.Actors.Actor)
  field(:command_name, 2, type: :string)
  field(:value, 3, type: Google.Protobuf.Any)
  field(:async, 4, type: :bool)
end

defmodule Eigr.Functions.Protocol.InvocationResponse do
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
      <<10, 18, 73, 110, 118, 111, 99, 97, 116, 105, 111, 110, 82, 101, 115, 112, 111, 110, 115,
        101, 18, 42, 10, 5, 118, 97, 108, 117, 101, 24, 1, 32, 1, 40, 11, 50, 20, 46, 103, 111,
        111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98, 117, 102, 46, 65, 110, 121, 82, 5,
        118, 97, 108, 117, 101, 18, 59, 10, 5, 97, 99, 116, 111, 114, 24, 2, 32, 1, 40, 11, 50,
        37, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114,
        111, 116, 111, 99, 111, 108, 46, 97, 99, 116, 111, 114, 115, 46, 65, 99, 116, 111, 114,
        82, 5, 97, 99, 116, 111, 114>>
    )
  end

  field(:value, 1, type: Google.Protobuf.Any)
  field(:actor, 2, type: Eigr.Functions.Protocol.Actors.Actor)
end

defmodule Eigr.Functions.Protocol.ActorInvocation do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          invocation_request: Eigr.Functions.Protocol.InvocationRequest.t() | nil
        }
  defstruct [:invocation_request]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 15, 65, 99, 116, 111, 114, 73, 110, 118, 111, 99, 97, 116, 105, 111, 110, 18, 89, 10,
        18, 105, 110, 118, 111, 99, 97, 116, 105, 111, 110, 95, 114, 101, 113, 117, 101, 115, 116,
        24, 1, 32, 1, 40, 11, 50, 42, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105,
        111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 73, 110, 118, 111, 99, 97,
        116, 105, 111, 110, 82, 101, 113, 117, 101, 115, 116, 82, 17, 105, 110, 118, 111, 99, 97,
        116, 105, 111, 110, 82, 101, 113, 117, 101, 115, 116>>
    )
  end

  field(:invocation_request, 1, type: Eigr.Functions.Protocol.InvocationRequest)
end

defmodule Eigr.Functions.Protocol.ActorInvocationResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          invocation_response: Eigr.Functions.Protocol.InvocationResponse.t() | nil,
          new_state: Google.Protobuf.Any.t() | nil
        }
  defstruct [:invocation_response, :new_state]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 23, 65, 99, 116, 111, 114, 73, 110, 118, 111, 99, 97, 116, 105, 111, 110, 82, 101,
        115, 112, 111, 110, 115, 101, 18, 92, 10, 19, 105, 110, 118, 111, 99, 97, 116, 105, 111,
        110, 95, 114, 101, 115, 112, 111, 110, 115, 101, 24, 1, 32, 1, 40, 11, 50, 43, 46, 101,
        105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116,
        111, 99, 111, 108, 46, 73, 110, 118, 111, 99, 97, 116, 105, 111, 110, 82, 101, 115, 112,
        111, 110, 115, 101, 82, 18, 105, 110, 118, 111, 99, 97, 116, 105, 111, 110, 82, 101, 115,
        112, 111, 110, 115, 101, 18, 49, 10, 9, 110, 101, 119, 95, 115, 116, 97, 116, 101, 24, 2,
        32, 1, 40, 11, 50, 20, 46, 103, 111, 111, 103, 108, 101, 46, 112, 114, 111, 116, 111, 98,
        117, 102, 46, 65, 110, 121, 82, 8, 110, 101, 119, 83, 116, 97, 116, 101>>
    )
  end

  field(:invocation_response, 1, type: Eigr.Functions.Protocol.InvocationResponse)
  field(:new_state, 2, type: Google.Protobuf.Any)
end

defmodule Eigr.Functions.Protocol.ActorSystemRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          message: {atom, any}
        }
  defstruct [:message]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 18, 65, 99, 116, 111, 114, 83, 121, 115, 116, 101, 109, 82, 101, 113, 117, 101, 115,
        116, 18, 97, 10, 20, 114, 101, 103, 105, 115, 116, 114, 97, 116, 105, 111, 110, 95, 114,
        101, 113, 117, 101, 115, 116, 24, 1, 32, 1, 40, 11, 50, 44, 46, 101, 105, 103, 114, 46,
        102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46,
        82, 101, 103, 105, 115, 116, 114, 97, 116, 105, 111, 110, 82, 101, 113, 117, 101, 115,
        116, 72, 0, 82, 19, 114, 101, 103, 105, 115, 116, 114, 97, 116, 105, 111, 110, 82, 101,
        113, 117, 101, 115, 116, 18, 91, 10, 18, 105, 110, 118, 111, 99, 97, 116, 105, 111, 110,
        95, 114, 101, 113, 117, 101, 115, 116, 24, 2, 32, 1, 40, 11, 50, 42, 46, 101, 105, 103,
        114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111,
        108, 46, 73, 110, 118, 111, 99, 97, 116, 105, 111, 110, 82, 101, 113, 117, 101, 115, 116,
        72, 0, 82, 17, 105, 110, 118, 111, 99, 97, 116, 105, 111, 110, 82, 101, 113, 117, 101,
        115, 116, 18, 110, 10, 25, 97, 99, 116, 111, 114, 95, 105, 110, 118, 111, 99, 97, 116,
        105, 111, 110, 95, 114, 101, 115, 112, 111, 110, 115, 101, 24, 3, 32, 1, 40, 11, 50, 48,
        46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111,
        116, 111, 99, 111, 108, 46, 65, 99, 116, 111, 114, 73, 110, 118, 111, 99, 97, 116, 105,
        111, 110, 82, 101, 115, 112, 111, 110, 115, 101, 72, 0, 82, 23, 97, 99, 116, 111, 114, 73,
        110, 118, 111, 99, 97, 116, 105, 111, 110, 82, 101, 115, 112, 111, 110, 115, 101, 66, 9,
        10, 7, 109, 101, 115, 115, 97, 103, 101>>
    )
  end

  oneof(:message, 0)
  field(:registration_request, 1, type: Eigr.Functions.Protocol.RegistrationRequest, oneof: 0)
  field(:invocation_request, 2, type: Eigr.Functions.Protocol.InvocationRequest, oneof: 0)

  field(:actor_invocation_response, 3,
    type: Eigr.Functions.Protocol.ActorInvocationResponse,
    oneof: 0
  )
end

defmodule Eigr.Functions.Protocol.ActorSystemResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          message: {atom, any}
        }
  defstruct [:message]

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.DescriptorProto.decode(
      <<10, 19, 65, 99, 116, 111, 114, 83, 121, 115, 116, 101, 109, 82, 101, 115, 112, 111, 110,
        115, 101, 18, 100, 10, 21, 114, 101, 103, 105, 115, 116, 114, 97, 116, 105, 111, 110, 95,
        114, 101, 115, 112, 111, 110, 115, 101, 24, 1, 32, 1, 40, 11, 50, 45, 46, 101, 105, 103,
        114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111,
        108, 46, 82, 101, 103, 105, 115, 116, 114, 97, 116, 105, 111, 110, 82, 101, 115, 112, 111,
        110, 115, 101, 72, 0, 82, 20, 114, 101, 103, 105, 115, 116, 114, 97, 116, 105, 111, 110,
        82, 101, 115, 112, 111, 110, 115, 101, 18, 85, 10, 16, 97, 99, 116, 111, 114, 95, 105,
        110, 118, 111, 99, 97, 116, 105, 111, 110, 24, 2, 32, 1, 40, 11, 50, 40, 46, 101, 105,
        103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99,
        111, 108, 46, 65, 99, 116, 111, 114, 73, 110, 118, 111, 99, 97, 116, 105, 111, 110, 72, 0,
        82, 15, 97, 99, 116, 111, 114, 73, 110, 118, 111, 99, 97, 116, 105, 111, 110, 18, 94, 10,
        19, 105, 110, 118, 111, 99, 97, 116, 105, 111, 110, 95, 114, 101, 115, 112, 111, 110, 115,
        101, 24, 3, 32, 1, 40, 11, 50, 43, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116,
        105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 73, 110, 118, 111, 99,
        97, 116, 105, 111, 110, 82, 101, 115, 112, 111, 110, 115, 101, 72, 0, 82, 18, 105, 110,
        118, 111, 99, 97, 116, 105, 111, 110, 82, 101, 115, 112, 111, 110, 115, 101, 66, 9, 10, 7,
        109, 101, 115, 115, 97, 103, 101>>
    )
  end

  oneof(:message, 0)
  field(:registration_response, 1, type: Eigr.Functions.Protocol.RegistrationResponse, oneof: 0)
  field(:actor_invocation, 2, type: Eigr.Functions.Protocol.ActorInvocation, oneof: 0)
  field(:invocation_response, 3, type: Eigr.Functions.Protocol.InvocationResponse, oneof: 0)
end

defmodule Eigr.Functions.Protocol.ActorService.Service do
  @moduledoc false
  use GRPC.Service, name: "eigr.functions.protocol.ActorService"

  def descriptor do
    # credo:disable-for-next-line
    Elixir.Google.Protobuf.ServiceDescriptorProto.decode(
      <<10, 12, 65, 99, 116, 111, 114, 83, 101, 114, 118, 105, 99, 101, 18, 102, 10, 5, 83, 112,
        97, 119, 110, 18, 43, 46, 101, 105, 103, 114, 46, 102, 117, 110, 99, 116, 105, 111, 110,
        115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 65, 99, 116, 111, 114, 83, 121, 115,
        116, 101, 109, 82, 101, 113, 117, 101, 115, 116, 26, 44, 46, 101, 105, 103, 114, 46, 102,
        117, 110, 99, 116, 105, 111, 110, 115, 46, 112, 114, 111, 116, 111, 99, 111, 108, 46, 65,
        99, 116, 111, 114, 83, 121, 115, 116, 101, 109, 82, 101, 115, 112, 111, 110, 115, 101, 40,
        1, 48, 1>>
    )
  end

  rpc(
    :Spawn,
    stream(Eigr.Functions.Protocol.ActorSystemRequest),
    stream(Eigr.Functions.Protocol.ActorSystemResponse)
  )
end

defmodule Eigr.Functions.Protocol.ActorService.Stub do
  @moduledoc false
  use GRPC.Stub, service: Eigr.Functions.Protocol.ActorService.Service
end
