defmodule Io.Cloudevents.V1.CloudEvent.AttributesEntry do
  @moduledoc false
  use Protobuf, map: true, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

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
          json_name: "key",
          label: :LABEL_OPTIONAL,
          name: "key",
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
          json_name: "value",
          label: :LABEL_OPTIONAL,
          name: "value",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".io.cloudevents.v1.CloudEvent.CloudEventAttributeValue"
        }
      ],
      name: "AttributesEntry",
      nested_type: [],
      oneof_decl: [],
      options: %Google.Protobuf.MessageOptions{
        __pb_extensions__: %{},
        __unknown_fields__: [],
        deprecated: false,
        map_entry: true,
        message_set_wire_format: false,
        no_standard_descriptor_accessor: false,
        uninterpreted_option: []
      },
      reserved_name: [],
      reserved_range: []
    }
  end

  field(:key, 1, type: :string)
  field(:value, 2, type: Io.Cloudevents.V1.CloudEvent.CloudEventAttributeValue)
end

defmodule Io.Cloudevents.V1.CloudEvent.CloudEventAttributeValue do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

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
          json_name: "ceBoolean",
          label: :LABEL_OPTIONAL,
          name: "ce_boolean",
          number: 1,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_BOOL,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "ceInteger",
          label: :LABEL_OPTIONAL,
          name: "ce_integer",
          number: 2,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_INT32,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "ceString",
          label: :LABEL_OPTIONAL,
          name: "ce_string",
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
          json_name: "ceBytes",
          label: :LABEL_OPTIONAL,
          name: "ce_bytes",
          number: 4,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_BYTES,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "ceUri",
          label: :LABEL_OPTIONAL,
          name: "ce_uri",
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
          json_name: "ceUriRef",
          label: :LABEL_OPTIONAL,
          name: "ce_uri_ref",
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
          json_name: "ceTimestamp",
          label: :LABEL_OPTIONAL,
          name: "ce_timestamp",
          number: 7,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Timestamp"
        }
      ],
      name: "CloudEventAttributeValue",
      nested_type: [],
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{__unknown_fields__: [], name: "attr", options: nil}
      ],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  oneof(:attr, 0)

  field(:ce_boolean, 1, type: :bool, json_name: "ceBoolean", oneof: 0)
  field(:ce_integer, 2, type: :int32, json_name: "ceInteger", oneof: 0)
  field(:ce_string, 3, type: :string, json_name: "ceString", oneof: 0)
  field(:ce_bytes, 4, type: :bytes, json_name: "ceBytes", oneof: 0)
  field(:ce_uri, 5, type: :string, json_name: "ceUri", oneof: 0)
  field(:ce_uri_ref, 6, type: :string, json_name: "ceUriRef", oneof: 0)
  field(:ce_timestamp, 7, type: Google.Protobuf.Timestamp, json_name: "ceTimestamp", oneof: 0)
end

defmodule Io.Cloudevents.V1.CloudEvent do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.11.0", syntax: :proto3

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
          json_name: "id",
          label: :LABEL_OPTIONAL,
          name: "id",
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
          json_name: "source",
          label: :LABEL_OPTIONAL,
          name: "source",
          number: 2,
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
          json_name: "specVersion",
          label: :LABEL_OPTIONAL,
          name: "spec_version",
          number: 3,
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
          json_name: "type",
          label: :LABEL_OPTIONAL,
          name: "type",
          number: 4,
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
          json_name: "attributes",
          label: :LABEL_REPEATED,
          name: "attributes",
          number: 5,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".io.cloudevents.v1.CloudEvent.AttributesEntry"
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "binaryData",
          label: :LABEL_OPTIONAL,
          name: "binary_data",
          number: 6,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_BYTES,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "textData",
          label: :LABEL_OPTIONAL,
          name: "text_data",
          number: 7,
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
          json_name: "protoData",
          label: :LABEL_OPTIONAL,
          name: "proto_data",
          number: 8,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Any"
        }
      ],
      name: "CloudEvent",
      nested_type: [
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
              json_name: "key",
              label: :LABEL_OPTIONAL,
              name: "key",
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
              json_name: "value",
              label: :LABEL_OPTIONAL,
              name: "value",
              number: 2,
              oneof_index: nil,
              options: nil,
              proto3_optional: nil,
              type: :TYPE_MESSAGE,
              type_name: ".io.cloudevents.v1.CloudEvent.CloudEventAttributeValue"
            }
          ],
          name: "AttributesEntry",
          nested_type: [],
          oneof_decl: [],
          options: %Google.Protobuf.MessageOptions{
            __pb_extensions__: %{},
            __unknown_fields__: [],
            deprecated: false,
            map_entry: true,
            message_set_wire_format: false,
            no_standard_descriptor_accessor: false,
            uninterpreted_option: []
          },
          reserved_name: [],
          reserved_range: []
        },
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
              json_name: "ceBoolean",
              label: :LABEL_OPTIONAL,
              name: "ce_boolean",
              number: 1,
              oneof_index: 0,
              options: nil,
              proto3_optional: nil,
              type: :TYPE_BOOL,
              type_name: nil
            },
            %Google.Protobuf.FieldDescriptorProto{
              __unknown_fields__: [],
              default_value: nil,
              extendee: nil,
              json_name: "ceInteger",
              label: :LABEL_OPTIONAL,
              name: "ce_integer",
              number: 2,
              oneof_index: 0,
              options: nil,
              proto3_optional: nil,
              type: :TYPE_INT32,
              type_name: nil
            },
            %Google.Protobuf.FieldDescriptorProto{
              __unknown_fields__: [],
              default_value: nil,
              extendee: nil,
              json_name: "ceString",
              label: :LABEL_OPTIONAL,
              name: "ce_string",
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
              json_name: "ceBytes",
              label: :LABEL_OPTIONAL,
              name: "ce_bytes",
              number: 4,
              oneof_index: 0,
              options: nil,
              proto3_optional: nil,
              type: :TYPE_BYTES,
              type_name: nil
            },
            %Google.Protobuf.FieldDescriptorProto{
              __unknown_fields__: [],
              default_value: nil,
              extendee: nil,
              json_name: "ceUri",
              label: :LABEL_OPTIONAL,
              name: "ce_uri",
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
              json_name: "ceUriRef",
              label: :LABEL_OPTIONAL,
              name: "ce_uri_ref",
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
              json_name: "ceTimestamp",
              label: :LABEL_OPTIONAL,
              name: "ce_timestamp",
              number: 7,
              oneof_index: 0,
              options: nil,
              proto3_optional: nil,
              type: :TYPE_MESSAGE,
              type_name: ".google.protobuf.Timestamp"
            }
          ],
          name: "CloudEventAttributeValue",
          nested_type: [],
          oneof_decl: [
            %Google.Protobuf.OneofDescriptorProto{
              __unknown_fields__: [],
              name: "attr",
              options: nil
            }
          ],
          options: nil,
          reserved_name: [],
          reserved_range: []
        }
      ],
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{__unknown_fields__: [], name: "data", options: nil}
      ],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  oneof(:data, 0)

  field(:id, 1, type: :string)
  field(:source, 2, type: :string)
  field(:spec_version, 3, type: :string, json_name: "specVersion")
  field(:type, 4, type: :string)

  field(:attributes, 5,
    repeated: true,
    type: Io.Cloudevents.V1.CloudEvent.AttributesEntry,
    map: true
  )

  field(:binary_data, 6, type: :bytes, json_name: "binaryData", oneof: 0)
  field(:text_data, 7, type: :string, json_name: "textData", oneof: 0)
  field(:proto_data, 8, type: Google.Protobuf.Any, json_name: "protoData", oneof: 0)
end
