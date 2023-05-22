defmodule Io.Eigr.Spawn.Example.MyState do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.10.0", syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      __unknown_fields__: [],
      enum_type: [],
      extension: [],
      extension_range: [],
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "value",
          label: :LABEL_OPTIONAL,
          name: "value",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_INT32,
          type_name: nil
        }
      ],
      name: "MyState",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :value, 1, type: :int32
end
defmodule Io.Eigr.Spawn.Example.MyBusinessMessage do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.10.0", syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      __unknown_fields__: [],
      enum_type: [],
      extension: [],
      extension_range: [],
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "value",
          label: :LABEL_OPTIONAL,
          name: "value",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_INT32,
          type_name: nil
        }
      ],
      name: "MyBusinessMessage",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :value, 1, type: :int32
end
defmodule Io.Eigr.Spawn.Example.TestService.Service do
  @moduledoc false
  use GRPC.Service, name: "io.eigr.spawn.example.TestService", protoc_gen_elixir_version: "0.10.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.ServiceDescriptorProto{
      __unknown_fields__: [],
      method: [
        %Google.Protobuf.MethodDescriptorProto{
          __unknown_fields__: [],
          client_streaming: false,
          input_type: ".io.eigr.spawn.example.MyBusinessMessage",
          name: "Sum",
          options: nil,
          output_type: ".io.eigr.spawn.example.MyBusinessMessage",
          server_streaming: false
        }
      ],
      name: "TestService",
      options: nil
    }
  end

  rpc :Sum, Io.Eigr.Spawn.Example.MyBusinessMessage, Io.Eigr.Spawn.Example.MyBusinessMessage
end

defmodule Io.Eigr.Spawn.Example.TestService.Stub do
  @moduledoc false
  use GRPC.Stub, service: Io.Eigr.Spawn.Example.TestService.Service
end
