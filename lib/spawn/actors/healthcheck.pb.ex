defmodule Eigr.Functions.Protocol.Actors.Healthcheck.Status do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

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

  field :status, 1, type: :string
  field :details, 2, type: :string
  field :updated_at, 3, type: Google.Protobuf.Timestamp, json_name: "updatedAt"
end

defmodule Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckState do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "HealthCheckState",
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
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "previous_status",
          extendee: nil,
          number: 2,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".eigr.functions.protocol.actors.healthcheck.Status",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "previousStatus",
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

  field :status, 1, type: Eigr.Functions.Protocol.Actors.Healthcheck.Status

  field :previous_status, 2,
    repeated: true,
    type: Eigr.Functions.Protocol.Actors.Healthcheck.Status,
    json_name: "previousStatus"
end

defmodule Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service do
  @moduledoc false
  use GRPC.Service,
    name: "eigr.functions.protocol.actors.healthcheck.HealthCheckActor",
    protoc_gen_elixir_version: "0.12.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.FileDescriptorProto{
      name: "healthcheck.proto",
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
          name: "HealthCheckState",
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
            },
            %Google.Protobuf.FieldDescriptorProto{
              name: "previous_status",
              extendee: nil,
              number: 2,
              label: :LABEL_REPEATED,
              type: :TYPE_MESSAGE,
              type_name: ".eigr.functions.protocol.actors.healthcheck.Status",
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "previousStatus",
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
              output_type: ".eigr.functions.protocol.actors.healthcheck.HealthCheckState",
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
                    pattern: {:get, "/v1/health/liveness"},
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
              output_type: ".eigr.functions.protocol.actors.healthcheck.HealthCheckState",
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
                    pattern: {:get, "/v1/health/readiness"},
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
            span: [0, 0, 38, 1],
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
            span: [18, 0, 21, 1],
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
            span: [19, 2, 20],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 0, 6],
            span: [19, 2, 8],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 0, 1],
            span: [19, 9, 15],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 0, 3],
            span: [19, 18, 19],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 1],
            span: [20, 2, 38],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 1, 4],
            span: [20, 2, 10],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 1, 6],
            span: [20, 11, 17],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 1, 1],
            span: [20, 18, 33],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [4, 1, 2, 1, 3],
            span: [20, 36, 37],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0],
            span: [24, 0, 38, 1],
            leading_comments: " The HealthCheck actor service definition.\n",
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 1],
            span: [24, 8, 24],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0],
            span: [27, 2, 31, 3],
            leading_comments: " Get Pong Message\n",
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 1],
            span: [27, 6, 14],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 2],
            span: [27, 15, 36],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 3],
            span: ~c"\e/?",
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4],
            span: [28, 4, 30, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4, 72_295_728],
            span: [28, 4, 30, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1],
            span: [33, 2, 37, 3],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 1],
            span: [33, 6, 15],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 2],
            span: [33, 16, 37],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 3],
            span: ~c"!0@",
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 4],
            span: [34, 4, 36, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 4, 72_295_728],
            span: [34, 4, 36, 6],
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
    Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckState,
    %{
      http: %{
        type: Google.Api.PbExtension,
        value: %Google.Api.HttpRule{
          selector: "",
          body: "",
          additional_bindings: [],
          response_body: "",
          pattern: {:get, "/v1/health/liveness"},
          __unknown_fields__: []
        }
      }
    }
  )

  rpc(
    :Readiness,
    Google.Protobuf.Empty,
    Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckState,
    %{
      http: %{
        type: Google.Api.PbExtension,
        value: %Google.Api.HttpRule{
          selector: "",
          body: "",
          additional_bindings: [],
          response_body: "",
          pattern: {:get, "/v1/health/readiness"},
          __unknown_fields__: []
        }
      }
    }
  )
end

defmodule Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.ActorDispatcher do
  @moduledoc since: "1.2.1"
  use GRPC.Server,
    service: Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service,
    http_transcode: true

  alias Sidecar.GRPC.Dispatcher

  @spec liveness(Google.Protobuf.Empty.t(), GRPC.Server.Stream.t()) ::
          Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckState.t()
  def liveness(message, stream) do
    request = %{
      system: "spawn-system",
      actor_name: "HealthCheckActor",
      action_name: "Liveness",
      input: message,
      stream: stream,
      descriptor: Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service.descriptor()
    }

    Dispatcher.dispatch(request)
  end

  @spec readiness(Google.Protobuf.Empty.t(), GRPC.Server.Stream.t()) ::
          Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckState.t()
  def readiness(message, stream) do
    request = %{
      system: "spawn-system",
      actor_name: "HealthCheckActor",
      action_name: "Readiness",
      input: message,
      stream: stream,
      descriptor: Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service.descriptor()
    }

    Dispatcher.dispatch(request)
  end
end

defmodule Sidecar.GRPC.ProxyEndpoint do
  @moduledoc false
  use GRPC.Endpoint

  intercept(GRPC.Server.Interceptors.Logger)

  services = [
    Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.ActorDispatcher
  ]

  services =
    [
      Sidecar.GRPC.Reflection.Server.V1,
      Sidecar.GRPC.Reflection.Server.V1Alpha
    ] ++ services

  run(services)
end

defmodule Sidecar.GRPC.ServiceResolver do
  @moduledoc since: "1.2.1"

  @actors [
    {
      "HealthCheckActor",
      %{
        service_name: "Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor",
        service_module: Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service
      }
    }
  ]

  def has_actor?(actor_name) do
    Enum.any?(@actors, fn {name, _} -> actor_name == name end)
  end

  def get_descriptor(actor_name) do
    actor_attributes =
      Enum.filter(@actors, fn {name, _} -> actor_name == name end)
      |> Enum.map(fn {_name, attributes} -> attributes end)
      |> List.first()

    mod = Map.get(actor_attributes, :service_module)

    mod.descriptor()
    |> Map.get(:service)
    |> Enum.filter(fn %Google.Protobuf.ServiceDescriptorProto{name: name} ->
      actor_name == name
    end)
    |> List.first()
  end
end

defmodule Sidecar.GRPC.Reflection.Server do
  @moduledoc since: "1.2.1"

  defmodule V1 do
    use GrpcReflection.Server,
      version: :v1,
      services: [
        Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service
      ]
  end

  defmodule V1Alpha do
    use GrpcReflection.Server,
      version: :v1alpha,
      services: [
        Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.Service
      ]
  end
end