defmodule HttpRule do
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
          json_name: "selector",
          label: :LABEL_OPTIONAL,
          name: "selector",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "get",
          label: :LABEL_OPTIONAL,
          name: "get",
          number: 2,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "put",
          label: :LABEL_OPTIONAL,
          name: "put",
          number: 3,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "post",
          label: :LABEL_OPTIONAL,
          name: "post",
          number: 4,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "delete",
          label: :LABEL_OPTIONAL,
          name: "delete",
          number: 5,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "patch",
          label: :LABEL_OPTIONAL,
          name: "patch",
          number: 6,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "custom",
          label: :LABEL_OPTIONAL,
          name: "custom",
          number: 8,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".CustomHttpPattern"
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "body",
          label: :LABEL_OPTIONAL,
          name: "body",
          number: 7,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "responseBody",
          label: :LABEL_OPTIONAL,
          name: "response_body",
          number: 12,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "additionalBindings",
          label: :LABEL_REPEATED,
          name: "additional_bindings",
          number: 11,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".HttpRule"
        }
      ],
      name: "HttpRule",
      nested_type: [],
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          __unknown_fields__: [],
          name: "pattern",
          options: nil
        }
      ],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  oneof :pattern, 0

  field :selector, 1, type: :string
  field :get, 2, type: :string, oneof: 0
  field :put, 3, type: :string, oneof: 0
  field :post, 4, type: :string, oneof: 0
  field :delete, 5, type: :string, oneof: 0
  field :patch, 6, type: :string, oneof: 0
  field :custom, 8, type: CustomHttpPattern, oneof: 0
  field :body, 7, type: :string
  field :response_body, 12, type: :string, json_name: "responseBody"
  field :additional_bindings, 11, repeated: true, type: HttpRule, json_name: "additionalBindings"
end
defmodule CustomHttpPattern do
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
          json_name: "kind",
          label: :LABEL_OPTIONAL,
          name: "kind",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "path",
          label: :LABEL_OPTIONAL,
          name: "path",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        }
      ],
      name: "CustomHttpPattern",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :kind, 1, type: :string
  field :path, 2, type: :string
end
