defmodule Example.Actors.ExampleActor.Service do
  use GRPC.Service, name: "example.actors.ExampleActor", protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.FileDescriptorProto{
      name: "actors/example.proto",
      package: "example.actors",
      dependency: ["google/api/annotations.proto", "example/example.proto"],
      message_type: [],
      enum_type: [],
      service: [
        %Google.Protobuf.ServiceDescriptorProto{
          name: "ExampleActor",
          method: [
            %Google.Protobuf.MethodDescriptorProto{
              name: "Sum",
              input_type: ".example.ValuePayload",
              output_type: ".example.SumResponse",
              options: %Google.Protobuf.MethodOptions{
                deprecated: false,
                idempotency_level: :IDEMPOTENCY_UNKNOWN,
                uninterpreted_option: [],
                __pb_extensions__: %{
                  {Google.Api.PbExtension, :http} => %Google.Api.HttpRule{
                    selector: "",
                    body: "*",
                    additional_bindings: [],
                    response_body: "",
                    pattern: {:post, "/v1/sum"},
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
      options: nil,
      source_code_info: %Google.Protobuf.SourceCodeInfo{
        location: [
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [],
            span: [0, 0, 14, 1],
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
            path: [3, 0],
            span: [2, 0, 38],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [3, 1],
            span: [3, 0, 31],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [2],
            span: [5, 0, 23],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0],
            span: [7, 0, 14, 1],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 1],
            span: [7, 8, 20],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0],
            span: [8, 2, 13, 3],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 1],
            span: [8, 6, 9],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 2],
            span: ~c"\b\v ",
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 3],
            span: ~c"\b+?",
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4],
            span: [9, 4, 12, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4, 72_295_728],
            span: [9, 4, 12, 6],
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

  rpc(:Sum, Example.ValuePayload, Example.SumResponse, %{
    http: %{
      type: Google.Api.PbExtension,
      value: %Google.Api.HttpRule{
        selector: "",
        body: "*",
        additional_bindings: [],
        response_body: "",
        pattern: {:post, "/v1/sum"},
        __unknown_fields__: []
      }
    }
  })
end

defmodule Example.Actors.ExampleActor.Stub do
  use GRPC.Stub, service: Example.Actors.ExampleActor.Service
end

defmodule Example.Actors.ExampleActor.ActorDispatcher do
  use GRPC.Server, service: Example.Actors.ExampleActor.Service, http_transcode: true

  alias Sidecar.GRPC.Dispatcher

  @spec sum(Example.ValuePayload.t(), GRPC.Server.Stream.t()) :: Example.SumResponse.t()
  def sum(message, stream) do
    request = %{
      system: "spawn-system",
      actor_name: "ExampleActor",
      action_name: "Sum",
      input: message,
      stream: stream,
      descriptor: Example.Actors.ExampleActor.Service.descriptor()
    }

    Dispatcher.dispatch(request)
  end
end

defmodule Sidecar.GRPC.ProxyEndpoint do
  use GRPC.Endpoint

  intercept(GRPC.Server.Interceptors.Logger)

  services = [
    Example.Actors.ExampleActor.ActorDispatcher
  ]

  services =
    [
      Sidecar.GRPC.Reflection.Server.V1,
      Sidecar.GRPC.Reflection.Server.V1Alpha,
      Eigr.Functions.Protocol.Actors.Healthcheck.HealthCheckActor.ActorDispatcher
    ] ++ services

  run(services)
end

defmodule Sidecar.GRPC.Reflection.Server do
  defmodule V1 do
    use GrpcReflection.Server,
      version: :v1,
      services: [
        Example.Actors.ExampleActor.Service
      ]
  end

  defmodule V1Alpha do
    use GrpcReflection.Server,
      version: :v1alpha,
      services: [
        Example.Actors.ExampleActor.Service
      ]
  end
end

defmodule Example.Actors.ExampleActor do
  @moduledoc "This module provides helper functions for invoking the methods on the Example.Actors.ExampleActor actor."

  @doc """
  Invokes the Sum method registered on ExampleActor.

  ## Parameters
  - `payload` - The payload to send to the action.
  - `opts` - The options to pass to the action.

  ## Examples
  ```elixir
  iex> Example.Actors.ExampleActor.sum(%Example.ValuePayload{}, async: false, metadata: %{"example" => "metadata"})
  {:ok, %Example.SumResponse{}}
  ```
  """
  @spec sum(Example.ValuePayload.t(), Keyword.t()) ::
          {:ok, Example.SumResponse.t()} | {:error, term()} | {:ok, :async}
  def sum(%Example.ValuePayload{} = payload \\ nil, opts \\ []) do
    opts = [
      system: opts[:system] || "spawn-system",
      action: "Sum",
      payload: payload,
      async: opts[:async] || false,
      metadata: opts[:metadata] || %{}
    ]

    actor_to_invoke = opts[:actor] || "ExampleActor"

    opts =
      if actor_to_invoke == "ExampleActor" do
        opts
      else
        Keyword.put(opts, :ref, "ExampleActor")
      end

    SpawnSdk.invoke(opts[:id] || "ExampleActor", opts)
  end
end