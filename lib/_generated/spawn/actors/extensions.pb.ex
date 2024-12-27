defmodule Spawn.Actors.PbExtension do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  extend(Google.Protobuf.FieldOptions, :actor_id, 9999,
    optional: true,
    type: :bool,
    json_name: "actorId"
  )

  extend(Google.Protobuf.MethodOptions, :view, 4_890_127,
    optional: true,
    type: Spawn.Actors.ActorViewOption
  )

  extend(Google.Protobuf.ServiceOptions, :actor, 4_890_128,
    optional: true,
    type: Spawn.Actors.ActorOpts
  )
end

defmodule Spawn.Actors.ActorViewOption do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ActorViewOption",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "query",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "query",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "map_to",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "mapTo",
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

  field(:query, 1, type: :string)
  field(:map_to, 2, type: :string, json_name: "mapTo")
end

defmodule Spawn.Actors.ActorOpts do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ActorOpts",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "state_type",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "stateType",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "stateful",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "stateful",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "deactivate_timeout",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_INT64,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "deactivateTimeout",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "snapshot_interval",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_INT64,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "snapshotInterval",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "sourceable",
          extendee: nil,
          number: 5,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "sourceable",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "strict_events_ordering",
          extendee: nil,
          number: 6,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "strictEventsOrdering",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "events_retention_strategy",
          extendee: nil,
          number: 7,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".spawn.actors.EventsRetentionStrategy",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "eventsRetentionStrategy",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "subjects",
          extendee: nil,
          number: 8,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".spawn.actors.ProjectionSubject",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "subjects",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "kind",
          extendee: nil,
          number: 9,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".spawn.actors.Kind",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "kind",
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

  field(:state_type, 1, type: :string, json_name: "stateType")
  field(:stateful, 2, type: :bool)
  field(:deactivate_timeout, 3, type: :int64, json_name: "deactivateTimeout")
  field(:snapshot_interval, 4, type: :int64, json_name: "snapshotInterval")
  field(:sourceable, 5, type: :bool)
  field(:strict_events_ordering, 6, type: :bool, json_name: "strictEventsOrdering")

  field(:events_retention_strategy, 7,
    type: Spawn.Actors.EventsRetentionStrategy,
    json_name: "eventsRetentionStrategy"
  )

  field(:subjects, 8, repeated: true, type: Spawn.Actors.ProjectionSubject)
  field(:kind, 9, type: Spawn.Actors.Kind, enum: true)
end
