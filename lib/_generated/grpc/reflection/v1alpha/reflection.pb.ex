defmodule Grpc.Reflection.V1alpha.ServerReflectionRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ServerReflectionRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "host",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "host",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "file_by_filename",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "fileByFilename",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "file_containing_symbol",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "fileContainingSymbol",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "file_containing_extension",
          extendee: nil,
          number: 5,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".grpc.reflection.v1alpha.ExtensionRequest",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "fileContainingExtension",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "all_extension_numbers_of_type",
          extendee: nil,
          number: 6,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "allExtensionNumbersOfType",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "list_services",
          extendee: nil,
          number: 7,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "listServices",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          name: "message_request",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  oneof(:message_request, 0)

  field(:host, 1, type: :string)
  field(:file_by_filename, 3, type: :string, json_name: "fileByFilename", oneof: 0)
  field(:file_containing_symbol, 4, type: :string, json_name: "fileContainingSymbol", oneof: 0)

  field(:file_containing_extension, 5,
    type: Grpc.Reflection.V1alpha.ExtensionRequest,
    json_name: "fileContainingExtension",
    oneof: 0
  )

  field(:all_extension_numbers_of_type, 6,
    type: :string,
    json_name: "allExtensionNumbersOfType",
    oneof: 0
  )

  field(:list_services, 7, type: :string, json_name: "listServices", oneof: 0)
end

defmodule Grpc.Reflection.V1alpha.ExtensionRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ExtensionRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "containing_type",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "containingType",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "extension_number",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_INT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "extensionNumber",
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

  field(:containing_type, 1, type: :string, json_name: "containingType")
  field(:extension_number, 2, type: :int32, json_name: "extensionNumber")
end

defmodule Grpc.Reflection.V1alpha.ServerReflectionResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ServerReflectionResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "valid_host",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "validHost",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "original_request",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".grpc.reflection.v1alpha.ServerReflectionRequest",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "originalRequest",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "file_descriptor_response",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".grpc.reflection.v1alpha.FileDescriptorResponse",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "fileDescriptorResponse",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "all_extension_numbers_response",
          extendee: nil,
          number: 5,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".grpc.reflection.v1alpha.ExtensionNumberResponse",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "allExtensionNumbersResponse",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "list_services_response",
          extendee: nil,
          number: 6,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".grpc.reflection.v1alpha.ListServiceResponse",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "listServicesResponse",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "error_response",
          extendee: nil,
          number: 7,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".grpc.reflection.v1alpha.ErrorResponse",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "errorResponse",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          name: "message_response",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  oneof(:message_response, 0)

  field(:valid_host, 1, type: :string, json_name: "validHost")

  field(:original_request, 2,
    type: Grpc.Reflection.V1alpha.ServerReflectionRequest,
    json_name: "originalRequest"
  )

  field(:file_descriptor_response, 4,
    type: Grpc.Reflection.V1alpha.FileDescriptorResponse,
    json_name: "fileDescriptorResponse",
    oneof: 0
  )

  field(:all_extension_numbers_response, 5,
    type: Grpc.Reflection.V1alpha.ExtensionNumberResponse,
    json_name: "allExtensionNumbersResponse",
    oneof: 0
  )

  field(:list_services_response, 6,
    type: Grpc.Reflection.V1alpha.ListServiceResponse,
    json_name: "listServicesResponse",
    oneof: 0
  )

  field(:error_response, 7,
    type: Grpc.Reflection.V1alpha.ErrorResponse,
    json_name: "errorResponse",
    oneof: 0
  )
end

defmodule Grpc.Reflection.V1alpha.FileDescriptorResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "FileDescriptorResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "file_descriptor_proto",
          extendee: nil,
          number: 1,
          label: :LABEL_REPEATED,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "fileDescriptorProto",
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

  field(:file_descriptor_proto, 1, repeated: true, type: :bytes, json_name: "fileDescriptorProto")
end

defmodule Grpc.Reflection.V1alpha.ExtensionNumberResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ExtensionNumberResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "base_type_name",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "baseTypeName",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "extension_number",
          extendee: nil,
          number: 2,
          label: :LABEL_REPEATED,
          type: :TYPE_INT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "extensionNumber",
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

  field(:base_type_name, 1, type: :string, json_name: "baseTypeName")
  field(:extension_number, 2, repeated: true, type: :int32, json_name: "extensionNumber")
end

defmodule Grpc.Reflection.V1alpha.ListServiceResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ListServiceResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "service",
          extendee: nil,
          number: 1,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".grpc.reflection.v1alpha.ServiceResponse",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "service",
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

  field(:service, 1, repeated: true, type: Grpc.Reflection.V1alpha.ServiceResponse)
end

defmodule Grpc.Reflection.V1alpha.ServiceResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ServiceResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "name",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "name",
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

  field(:name, 1, type: :string)
end

defmodule Grpc.Reflection.V1alpha.ErrorResponse do
  @moduledoc false
  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ErrorResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "error_code",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_INT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "errorCode",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "error_message",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "errorMessage",
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

  field(:error_code, 1, type: :int32, json_name: "errorCode")
  field(:error_message, 2, type: :string, json_name: "errorMessage")
end
