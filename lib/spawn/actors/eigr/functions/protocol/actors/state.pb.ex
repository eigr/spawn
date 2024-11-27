defmodule Eigr.Functions.Protocol.State.Revision do
  @moduledoc false
<<<<<<< HEAD
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
=======
  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3
>>>>>>> main

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "Revision",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "value",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_INT64,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "value",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field(:value, 1, type: :int64)
end

defmodule Eigr.Functions.Protocol.State.Checkpoint do
  @moduledoc false
<<<<<<< HEAD
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
=======
  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3
>>>>>>> main

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "Checkpoint",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "revision",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.state.Revision",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "revision",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "state",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.ActorState",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "state",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field(:revision, 1, type: Eigr.Functions.Protocol.State.Revision)
  field(:state, 2, type: Eigr.Functions.Protocol.Actors.ActorState)
end
