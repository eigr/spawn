defmodule Eigr.Functions.Protocol.Actors.Healthcheck.Status do
  @moduledoc false
<<<<<<< HEAD
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
=======
  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3
>>>>>>> main

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "Status",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "status",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "status",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "details",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "details",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "updated_at",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Timestamp",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "updatedAt",
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

  field(:status, 1, type: :string)
  field(:details, 2, type: :string)
  field(:updated_at, 3, type: Google.Protobuf.Timestamp, json_name: "updatedAt")
end

defmodule Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckReply do
  @moduledoc false
<<<<<<< HEAD
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
=======
  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3
>>>>>>> main

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "HealthCheckReply",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "status",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.healthcheck.Status",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "status",
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

  field(:status, 1, type: Eigr.Functions.Protocol.Actors.Healthcheck.Status)
end

defmodule Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service do
  @moduledoc false

  use GRPC.Service,
    name: "eigr.functions.protocol.actors.healthcheck.HealthCheckActor",
    protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.FileDescriptorProto{
      name: "eigr/functions/protocol/actors/healthcheck.proto",
      package: "eigr.functions.protocol.actors.healthcheck",
      dependency: [
        "google/api/annotations.proto",
        "google/protobuf/empty.proto",
        "google/protobuf/timestamp.proto",
        "eigr/functions/protocol/actors/extensions.proto"
      ],
      message_type: [
        %Google.Protobuf.DescriptorProto{
          name: "Status",
          field: [
            %Google.Protobuf.FieldDescriptorProto{
              name: "status",
              extendee: nil,
              number: 1,
              label: :LABEL_OPTIONAL,
              type: :TYPE_STRING,
              type_name: nil,
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "status",
              proto3_optional: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.FieldDescriptorProto{
              name: "details",
              extendee: nil,
              number: 2,
              label: :LABEL_OPTIONAL,
              type: :TYPE_STRING,
              type_name: nil,
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "details",
              proto3_optional: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.FieldDescriptorProto{
              name: "updated_at",
              extendee: nil,
              number: 3,
              label: :LABEL_OPTIONAL,
              type: :TYPE_MESSAGE,
              type_name: ".google.protobuf.Timestamp",
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "updatedAt",
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
        },
        %Google.Protobuf.DescriptorProto{
          name: "HealthCheckReply",
          field: [
            %Google.Protobuf.FieldDescriptorProto{
              name: "status",
              extendee: nil,
              number: 1,
              label: :LABEL_OPTIONAL,
              type: :TYPE_MESSAGE,
              type_name: ".eigr.functions.protocol.actors.healthcheck.Status",
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "status",
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
      ],
      enum_type: [],
      service: [
        %Google.Protobuf.ServiceDescriptorProto{
          name: "HealthCheckActor",
          method: [
            %Google.Protobuf.MethodDescriptorProto{
              name: "Liveness",
              input_type: ".google.protobuf.Empty",
              output_type: ".eigr.functions.protocol.actors.healthcheck.HealthCheckReply",
              options: %Google.Protobuf.MethodOptions{
                deprecated: false,
                idempotency_level: :IDEMPOTENCY_UNKNOWN,
                uninterpreted_option: [],
                __pb_extensions__: %{
                  {Google.Api.PbExtension, :http} => %Google.Api.HttpRule{
                    selector: "",
                    body: "",
                    additional_bindings: [],
                    response_body: "",
                    pattern: {:get, "/health/liveness"},
                    __unknown_fields__: []
                  }
                },
                __unknown_fields__: []
              },
              client_streaming: false,
              server_streaming: false,
              __unknown_fields__: []
            },
            %Google.Protobuf.MethodDescriptorProto{
              name: "Readiness",
              input_type: ".google.protobuf.Empty",
              output_type: ".eigr.functions.protocol.actors.healthcheck.HealthCheckReply",
              options: %Google.Protobuf.MethodOptions{
                deprecated: false,
                idempotency_level: :IDEMPOTENCY_UNKNOWN,
                uninterpreted_option: [],
                __pb_extensions__: %{
                  {Google.Api.PbExtension, :http} => %Google.Api.HttpRule{
                    selector: "",
                    body: "",
                    additional_bindings: [],
                    response_body: "",
                    pattern: {:get, "/health/readiness"},
                    __unknown_fields__: []
                  }
                },
                __unknown_fields__: []
              },
              client_streaming: false,
              server_streaming: false,
              __unknown_fields__: []
            }
          ],
          options: nil,
          __unknown_fields__: []
        }
      ],
      extension: [],
      options: %Google.Protobuf.FileOptions{
        java_package: nil,
        java_outer_classname: nil,
        optimize_for: :SPEED,
        java_multiple_files: false,
        go_package: nil,
        cc_generic_services: false,
        java_generic_services: false,
        py_generic_services: false,
        java_generate_equals_and_hash: nil,
        deprecated: false,
        java_string_check_utf8: false,
        cc_enable_arenas: true,
        objc_class_prefix: "HLW",
        csharp_namespace: nil,
        swift_prefix: nil,
        php_class_prefix: nil,
        php_namespace: nil,
        php_generic_services: false,
        php_metadata_namespace: nil,
        ruby_package: nil,
        uninterpreted_option: [],
        __pb_extensions__: %{},
        __unknown_fields__: []
      },
      source_code_info: %Google.Protobuf.SourceCodeInfo{
        location: [
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [],
            span: [0, 0, 35, 1],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: ~c"\f",
            span: [0, 0, 18],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: ~c"\b",
            span: [2, 0, 33],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: ~c"\b$",
            span: [2, 0, 33],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [3, 0],
            span: [4, 0, 38],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [3, 1],
            span: [5, 0, 37],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [3, 2],
            span: [6, 0, 41],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [3, 3],
            span: [7, 0, 57],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [2],
            span: [9, 0, 51],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0],
            span: [11, 0, 15, 1],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 1],
            span: [11, 8, 14],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 0],
            span: [12, 2, 20],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 0, 5],
            span: [12, 2, 8],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 0, 1],
            span: [12, 9, 15],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 0, 3],
            span: [12, 18, 19],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 1],
            span: [13, 2, 21],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 1, 5],
            span: [13, 2, 8],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 1, 1],
            span: [13, 9, 16],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 1, 3],
            span: [13, 19, 20],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 2],
            span: [14, 2, 43],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 2, 6],
            span: [14, 2, 27],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 2, 1],
            span: [14, 28, 38],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 0, 2, 2, 3],
            span: [14, 41, 42],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1],
            span: [18, 0, 47],
            leading_comments: " The state of HealthCheckActor\n",
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 1],
            span: [18, 8, 24],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 0],
            span: [18, 27, 45],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 0, 6],
            span: [18, 27, 33],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 0, 1],
            span: [18, 34, 40],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 0, 3],
            span: [18, 43, 44],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0],
            span: [21, 0, 35, 1],
            leading_comments: " The HealthCheck actor service definition.\n",
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 1],
            span: [21, 8, 24],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0],
            span: [24, 2, 28, 3],
            leading_comments: " Get Pong Message\n",
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 1],
            span: [24, 6, 14],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 2],
            span: [24, 15, 36],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 3],
            span: [24, 47, 63],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4],
            span: [25, 4, 27, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4, 72_295_728],
            span: [25, 4, 27, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1],
            span: [30, 2, 34, 3],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 1],
            span: [30, 6, 15],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 2],
            span: [30, 16, 37],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 3],
            span: [30, 48, 64],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 4],
            span: [31, 4, 33, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 4, 72_295_728],
            span: [31, 4, 33, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          }
        ],
        __unknown_fields__: []
      },
      public_dependency: [],
      weak_dependency: [],
      syntax: "proto3",
      edition: nil,
      __unknown_fields__: []
    }
  end

  rpc(
    :Liveness,
    Google.Protobuf.Empty,
    Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckReply,
    %{
      http: %{
        type: Google.Api.PbExtension,
        value: %Google.Api.HttpRule{
          selector: "",
          body: "",
          additional_bindings: [],
          response_body: "",
          pattern: {:get, "/health/liveness"},
          __unknown_fields__: []
        }
      }
    }
  )

  rpc(
    :Readiness,
    Google.Protobuf.Empty,
    Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckReply,
    %{
      http: %{
        type: Google.Api.PbExtension,
        value: %Google.Api.HttpRule{
          selector: "",
          body: "",
          additional_bindings: [],
          response_body: "",
          pattern: {:get, "/health/readiness"},
          __unknown_fields__: []
        }
      }
    }
  )
end

defmodule Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Stub do
  @moduledoc false

  use GRPC.Stub, service: Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service
end
