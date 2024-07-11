defmodule X509SVIDRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.10.0", syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      __unknown_fields__: [],
      enum_type: [],
      extension: [],
      extension_range: [],
      field: [],
      name: "X509SVIDRequest",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end
end
defmodule X509SVIDResponse.FederatedBundlesEntry do
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
          type: :TYPE_BYTES,
          type_name: nil
        }
      ],
      name: "FederatedBundlesEntry",
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
  field :value, 2, type: :bytes
end
defmodule X509SVIDResponse do
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
          json_name: "svids",
          label: :LABEL_REPEATED,
          name: "svids",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".X509SVID"
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "crl",
          label: :LABEL_REPEATED,
          name: "crl",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_BYTES,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "federatedBundles",
          label: :LABEL_REPEATED,
          name: "federated_bundles",
          number: 3,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".X509SVIDResponse.FederatedBundlesEntry"
        }
      ],
      name: "X509SVIDResponse",
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
              type: :TYPE_BYTES,
              type_name: nil
            }
          ],
          name: "FederatedBundlesEntry",
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

  field :svids, 1, repeated: true, type: X509SVID
  field :crl, 2, repeated: true, type: :bytes

  field :federated_bundles, 3,
    repeated: true,
    type: X509SVIDResponse.FederatedBundlesEntry,
    json_name: "federatedBundles"
end
defmodule X509SVID do
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
          json_name: "spiffeId",
          label: :LABEL_OPTIONAL,
          name: "spiffe_id",
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
          json_name: "x509Svid",
          label: :LABEL_OPTIONAL,
          name: "x509_svid",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_BYTES,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "x509SvidKey",
          label: :LABEL_OPTIONAL,
          name: "x509_svid_key",
          number: 3,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_BYTES,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "bundle",
          label: :LABEL_OPTIONAL,
          name: "bundle",
          number: 4,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_BYTES,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "hint",
          label: :LABEL_OPTIONAL,
          name: "hint",
          number: 5,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        }
      ],
      name: "X509SVID",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :spiffe_id, 1, type: :string, json_name: "spiffeId"
  field :x509_svid, 2, type: :bytes, json_name: "x509Svid"
  field :x509_svid_key, 3, type: :bytes, json_name: "x509SvidKey"
  field :bundle, 4, type: :bytes
  field :hint, 5, type: :string
end
defmodule X509BundlesRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.10.0", syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      __unknown_fields__: [],
      enum_type: [],
      extension: [],
      extension_range: [],
      field: [],
      name: "X509BundlesRequest",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end
end
defmodule X509BundlesResponse.BundlesEntry do
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
          type: :TYPE_BYTES,
          type_name: nil
        }
      ],
      name: "BundlesEntry",
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
  field :value, 2, type: :bytes
end
defmodule X509BundlesResponse do
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
          json_name: "crl",
          label: :LABEL_REPEATED,
          name: "crl",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_BYTES,
          type_name: nil
        },
        %Google.Protobuf.FieldDescriptorProto{
          __unknown_fields__: [],
          default_value: nil,
          extendee: nil,
          json_name: "bundles",
          label: :LABEL_REPEATED,
          name: "bundles",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".X509BundlesResponse.BundlesEntry"
        }
      ],
      name: "X509BundlesResponse",
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
              type: :TYPE_BYTES,
              type_name: nil
            }
          ],
          name: "BundlesEntry",
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

  field :crl, 1, repeated: true, type: :bytes
  field :bundles, 2, repeated: true, type: X509BundlesResponse.BundlesEntry
end
defmodule JWTSVIDRequest do
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
          json_name: "audience",
          label: :LABEL_REPEATED,
          name: "audience",
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
          json_name: "spiffeId",
          label: :LABEL_OPTIONAL,
          name: "spiffe_id",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        }
      ],
      name: "JWTSVIDRequest",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :audience, 1, repeated: true, type: :string
  field :spiffe_id, 2, type: :string, json_name: "spiffeId"
end
defmodule JWTSVIDResponse do
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
          json_name: "svids",
          label: :LABEL_REPEATED,
          name: "svids",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".JWTSVID"
        }
      ],
      name: "JWTSVIDResponse",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :svids, 1, repeated: true, type: JWTSVID
end
defmodule JWTSVID do
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
          json_name: "spiffeId",
          label: :LABEL_OPTIONAL,
          name: "spiffe_id",
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
          json_name: "svid",
          label: :LABEL_OPTIONAL,
          name: "svid",
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
          json_name: "hint",
          label: :LABEL_OPTIONAL,
          name: "hint",
          number: 3,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        }
      ],
      name: "JWTSVID",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :spiffe_id, 1, type: :string, json_name: "spiffeId"
  field :svid, 2, type: :string
  field :hint, 3, type: :string
end
defmodule JWTBundlesRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.10.0", syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      __unknown_fields__: [],
      enum_type: [],
      extension: [],
      extension_range: [],
      field: [],
      name: "JWTBundlesRequest",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end
end
defmodule JWTBundlesResponse.BundlesEntry do
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
          type: :TYPE_BYTES,
          type_name: nil
        }
      ],
      name: "BundlesEntry",
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
  field :value, 2, type: :bytes
end
defmodule JWTBundlesResponse do
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
          json_name: "bundles",
          label: :LABEL_REPEATED,
          name: "bundles",
          number: 1,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".JWTBundlesResponse.BundlesEntry"
        }
      ],
      name: "JWTBundlesResponse",
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
              type: :TYPE_BYTES,
              type_name: nil
            }
          ],
          name: "BundlesEntry",
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

  field :bundles, 1, repeated: true, type: JWTBundlesResponse.BundlesEntry
end
defmodule ValidateJWTSVIDRequest do
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
          json_name: "audience",
          label: :LABEL_OPTIONAL,
          name: "audience",
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
          json_name: "svid",
          label: :LABEL_OPTIONAL,
          name: "svid",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_STRING,
          type_name: nil
        }
      ],
      name: "ValidateJWTSVIDRequest",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :audience, 1, type: :string
  field :svid, 2, type: :string
end
defmodule ValidateJWTSVIDResponse do
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
          json_name: "spiffeId",
          label: :LABEL_OPTIONAL,
          name: "spiffe_id",
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
          json_name: "claims",
          label: :LABEL_OPTIONAL,
          name: "claims",
          number: 2,
          oneof_index: nil,
          options: nil,
          proto3_optional: nil,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Struct"
        }
      ],
      name: "ValidateJWTSVIDResponse",
      nested_type: [],
      oneof_decl: [],
      options: nil,
      reserved_name: [],
      reserved_range: []
    }
  end

  field :spiffe_id, 1, type: :string, json_name: "spiffeId"
  field :claims, 2, type: Google.Protobuf.Struct
end
defmodule SpiffeWorkloadAPI.Service do
  @moduledoc false
  use GRPC.Service, name: "SpiffeWorkloadAPI", protoc_gen_elixir_version: "0.10.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.ServiceDescriptorProto{
      __unknown_fields__: [],
      method: [
        %Google.Protobuf.MethodDescriptorProto{
          __unknown_fields__: [],
          client_streaming: false,
          input_type: ".X509SVIDRequest",
          name: "FetchX509SVID",
          options: nil,
          output_type: ".X509SVIDResponse",
          server_streaming: true
        },
        %Google.Protobuf.MethodDescriptorProto{
          __unknown_fields__: [],
          client_streaming: false,
          input_type: ".X509BundlesRequest",
          name: "FetchX509Bundles",
          options: nil,
          output_type: ".X509BundlesResponse",
          server_streaming: true
        },
        %Google.Protobuf.MethodDescriptorProto{
          __unknown_fields__: [],
          client_streaming: false,
          input_type: ".JWTSVIDRequest",
          name: "FetchJWTSVID",
          options: nil,
          output_type: ".JWTSVIDResponse",
          server_streaming: false
        },
        %Google.Protobuf.MethodDescriptorProto{
          __unknown_fields__: [],
          client_streaming: false,
          input_type: ".JWTBundlesRequest",
          name: "FetchJWTBundles",
          options: nil,
          output_type: ".JWTBundlesResponse",
          server_streaming: true
        },
        %Google.Protobuf.MethodDescriptorProto{
          __unknown_fields__: [],
          client_streaming: false,
          input_type: ".ValidateJWTSVIDRequest",
          name: "ValidateJWTSVID",
          options: nil,
          output_type: ".ValidateJWTSVIDResponse",
          server_streaming: false
        }
      ],
      name: "SpiffeWorkloadAPI",
      options: nil
    }
  end

  rpc :FetchX509SVID, X509SVIDRequest, stream(X509SVIDResponse)

  rpc :FetchX509Bundles, X509BundlesRequest, stream(X509BundlesResponse)

  rpc :FetchJWTSVID, JWTSVIDRequest, JWTSVIDResponse

  rpc :FetchJWTBundles, JWTBundlesRequest, stream(JWTBundlesResponse)

  rpc :ValidateJWTSVID, ValidateJWTSVIDRequest, ValidateJWTSVIDResponse
end

defmodule SpiffeWorkloadAPI.Stub do
  @moduledoc false
  use GRPC.Stub, service: SpiffeWorkloadAPI.Service
end
