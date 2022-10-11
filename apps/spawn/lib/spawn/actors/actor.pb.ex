defmodule Eigr.Functions.Protocol.Actors.Registry.ActorsEntry do
  @moduledoc false
  use Protobuf, map: true, protoc_gen_elixir_version: "0.10.0", syntax: :proto3

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
          type_name: ".eigr.functions.protocol.actors.Actor"
        }
      ],
      name: "ActorsEntry",
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

  field :key, 1, type: :string
  field :value, 2, type: Eigr.Functions.Protocol.Actors.Actor
end
defmodule Eigr.Functions.Protocol.Actors.Registry do
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
          json_name: "actors",
          label: :LABEL_REPEATED,
          name: "actors",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.Registry.ActorsEntry"
        }
      ],
      name: "Registry",
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
              type_name: ".eigr.functions.protocol.actors.Actor"
            }
          ],
          name: "ActorsEntry",
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
      ],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :actors, 1,
    repeated: true,
    type: Eigr.Functions.Protocol.Actors.Registry.ActorsEntry,
    map: true
end
defmodule Eigr.Functions.Protocol.Actors.ActorSystem do
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
          json_name: "name",
          label: :LABEL_OPTIONAL,
          name: "name",
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
          json_name: "registry",
          label: :LABEL_OPTIONAL,
          name: "registry",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.Registry"
        }
      ],
      name: "ActorSystem",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :name, 1, type: :string
  field :registry, 2, type: Eigr.Functions.Protocol.Actors.Registry
end
defmodule Eigr.Functions.Protocol.Actors.ActorSnapshotStrategy do
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
          json_name: "timeout",
          label: :LABEL_OPTIONAL,
          name: "timeout",
          number: 1,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.TimeoutStrategy"
        }
      ],
      name: "ActorSnapshotStrategy",
      nested_type: [],
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          __unknown_fields__: [],
          name: "strategy",
          options: nil
        }
      ],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  oneof :strategy, 0

  field :timeout, 1, type: Eigr.Functions.Protocol.Actors.TimeoutStrategy, oneof: 0
end
defmodule Eigr.Functions.Protocol.Actors.ActorDeactivateStrategy do
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
          json_name: "timeout",
          label: :LABEL_OPTIONAL,
          name: "timeout",
          number: 1,
          oneof_index: 0,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.TimeoutStrategy"
        }
      ],
      name: "ActorDeactivateStrategy",
      nested_type: [],
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          __unknown_fields__: [],
          name: "strategy",
          options: nil
        }
      ],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  oneof :strategy, 0

  field :timeout, 1, type: Eigr.Functions.Protocol.Actors.TimeoutStrategy, oneof: 0
end
defmodule Eigr.Functions.Protocol.Actors.TimeoutStrategy do
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
          json_name: "timeout",
          label: :LABEL_OPTIONAL,
          name: "timeout",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_INT64,
          type_name: nil
        }
      ],
      name: "TimeoutStrategy",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :timeout, 1, type: :int64
end
defmodule Eigr.Functions.Protocol.Actors.Command do
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
          json_name: "name",
          label: :LABEL_OPTIONAL,
          name: "name",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        }
      ],
      name: "Command",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :name, 1, type: :string
end
defmodule Eigr.Functions.Protocol.Actors.FixedTimerCommand do
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
          json_name: "seconds",
          label: :LABEL_OPTIONAL,
          name: "seconds",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_INT32,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "command",
          label: :LABEL_OPTIONAL,
          name: "command",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.Command"
        }
      ],
      name: "FixedTimerCommand",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :seconds, 1, type: :int32
  field :command, 2, type: Eigr.Functions.Protocol.Actors.Command
end
defmodule Eigr.Functions.Protocol.Actors.ActorState.TagsEntry do
  @moduledoc false
  use Protobuf, map: true, protoc_gen_elixir_version: "0.10.0", syntax: :proto3

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
          type: :TYPE_STRING,
          type_name: nil
        }
      ],
      name: "TagsEntry",
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

  field :key, 1, type: :string
  field :value, 2, type: :string
end
defmodule Eigr.Functions.Protocol.Actors.ActorState do
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
          json_name: "tags",
          label: :LABEL_REPEATED,
          name: "tags",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.ActorState.TagsEntry"
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "state",
          label: :LABEL_OPTIONAL,
          name: "state",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Any"
        }
      ],
      name: "ActorState",
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
              type: :TYPE_STRING,
              type_name: nil
            }
          ],
          name: "TagsEntry",
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
      ],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :tags, 1,
    repeated: true,
    type: Eigr.Functions.Protocol.Actors.ActorState.TagsEntry,
    map: true

  field :state, 2, type: Google.Protobuf.Any
end
defmodule Eigr.Functions.Protocol.Actors.ActorSettings do
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
          json_name: "abstract",
          label: :LABEL_OPTIONAL,
          name: "abstract",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_BOOL,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "persistent",
          label: :LABEL_OPTIONAL,
          name: "persistent",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_BOOL,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "snapshotStrategy",
          label: :LABEL_OPTIONAL,
          name: "snapshot_strategy",
          number: 3,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.ActorSnapshotStrategy"
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "deactivateStrategy",
          label: :LABEL_OPTIONAL,
          name: "deactivate_strategy",
          number: 4,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.ActorDeactivateStrategy"
        }
      ],
      name: "ActorSettings",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :abstract, 1, type: :bool
  field :persistent, 2, type: :bool

  field :snapshot_strategy, 3,
    type: Eigr.Functions.Protocol.Actors.ActorSnapshotStrategy,
    json_name: "snapshotStrategy"

  field :deactivate_strategy, 4,
    type: Eigr.Functions.Protocol.Actors.ActorDeactivateStrategy,
    json_name: "deactivateStrategy"
end
defmodule Eigr.Functions.Protocol.Actors.ActorId do
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
          json_name: "name",
          label: :LABEL_OPTIONAL,
          name: "name",
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
          json_name: "system",
          label: :LABEL_OPTIONAL,
          name: "system",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        }
      ],
      name: "ActorId",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :name, 1, type: :string
  field :system, 2, type: :string
end
defmodule Eigr.Functions.Protocol.Actors.Actor do
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
          json_name: "id",
          label: :LABEL_OPTIONAL,
          name: "id",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.ActorId"
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "state",
          label: :LABEL_OPTIONAL,
          name: "state",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.ActorState"
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "settings",
          label: :LABEL_OPTIONAL,
          name: "settings",
          number: 3,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.ActorSettings"
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "commands",
          label: :LABEL_REPEATED,
          name: "commands",
          number: 4,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.Command"
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "timerCommands",
          label: :LABEL_REPEATED,
          name: "timer_commands",
          number: 5,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.FixedTimerCommand"
        }
      ],
      name: "Actor",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :id, 1, type: Eigr.Functions.Protocol.Actors.ActorId
  field :state, 2, type: Eigr.Functions.Protocol.Actors.ActorState
  field :settings, 3, type: Eigr.Functions.Protocol.Actors.ActorSettings
  field :commands, 4, repeated: true, type: Eigr.Functions.Protocol.Actors.Command

  field :timer_commands, 5,
    repeated: true,
    type: Eigr.Functions.Protocol.Actors.FixedTimerCommand,
    json_name: "timerCommands"
end
