defmodule Example.Actors.ExampleActor.Service do
  use GRPC.Service, name: "example.actors.ExampleActor", protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.FileDescriptorProto{
      name: "actors/example.proto",
      package: "example.actors",
      dependency: [
        "google/api/annotations.proto",
        "example/example.proto",
        "spawn/actors/extensions.proto"
      ],
      message_type: [],
      enum_type: [],
      service: [
        %Google.Protobuf.ServiceDescriptorProto{
          name: "ExampleActor",
          method: [
            %Google.Protobuf.MethodDescriptorProto{
              name: "ExampleView",
              input_type: ".example.ValuePayload",
              output_type: ".example.SomeQueryResponse",
              options: %Google.Protobuf.MethodOptions{
                deprecated: false,
                idempotency_level: :IDEMPOTENCY_UNKNOWN,
                uninterpreted_option: [],
                __pb_extensions__: %{
                  {Spawn.Actors.PbExtension, :view} => %Spawn.Actors.ActorViewOption{
                    query: "SELECT id, name, age WHERE name = :customer_name",
                    map_to: "results",
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
              name: "ActionA",
              input_type: ".example.ValuePayload",
              output_type: ".example.SomeQueryResponse",
              options: %Google.Protobuf.MethodOptions{
                deprecated: false,
                idempotency_level: :IDEMPOTENCY_UNKNOWN,
                uninterpreted_option: [],
                __pb_extensions__: %{},
                __unknown_fields__: []
              },
              client_streaming: false,
              server_streaming: false,
              __unknown_fields__: []
            }
          ],
          options: %Google.Protobuf.ServiceOptions{
            deprecated: false,
            uninterpreted_option: [],
            __pb_extensions__: %{
              {Spawn.Actors.PbExtension, :settings} => %Spawn.Actors.ActorSettings{
                kind: :PROJECTION,
                stateful: true,
                snapshot_strategy: %Spawn.Actors.ActorSnapshotStrategy{
                  strategy: {:duration_ms, 60000},
                  __unknown_fields__: []
                },
                deactivation_strategy: %Spawn.Actors.ActorDeactivationStrategy{
                  strategy: {:duration_ms, 30000},
                  __unknown_fields__: []
                },
                min_pool_size: 0,
                max_pool_size: 0,
                projection_settings: %Spawn.Actors.ProjectionSettings{
                  subjects: [
                    %Spawn.Actors.ProjectionSubject{
                      actor: "ActorA",
                      action: "ActionA",
                      start_time: %Google.Protobuf.Timestamp{
                        seconds: 1_672_531_200,
                        nanos: 0,
                        __unknown_fields__: []
                      },
                      __unknown_fields__: []
                    }
                  ],
                  sourceable: false,
                  events_retention_strategy: %Spawn.Actors.EventsRetentionStrategy{
                    strategy: {:duration_ms, 86_400_000},
                    __unknown_fields__: []
                  },
                  strict_events_ordering: false,
                  __unknown_fields__: []
                },
                state_type: ".example.ExampleState",
                __unknown_fields__: []
              }
            },
            __unknown_fields__: []
          },
          __unknown_fields__: []
        }
      ],
      extension: [],
      options: nil,
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
            path: [3, 2],
            span: [4, 0, 39],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [2],
            span: [6, 0, 23],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0],
            span: [8, 0, 38, 1],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 1],
            span: [8, 8, 20],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 3],
            span: [9, 2, 28, 4],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 3, 4_890_128],
            span: [9, 2, 28, 4],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0],
            span: [30, 2, 35, 3],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 1],
            span: [30, 6, 17],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 2],
            span: [30, 19, 40],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 3],
            span: [30, 51, 77],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4],
            span: [31, 4, 34, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4, 4_890_127],
            span: [31, 4, 34, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1],
            span: [37, 2, 78],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 1],
            span: [37, 6, 13],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 2],
            span: [37, 15, 36],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 3],
            span: ~c"%/I",
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

  rpc(:ExampleView, Example.ValuePayload, Example.SomeQueryResponse, %{
    view: %{
      type: Spawn.Actors.PbExtension,
      value: %Spawn.Actors.ActorViewOption{
        query: "SELECT id, name, age WHERE name = :customer_name",
        map_to: "results",
        __unknown_fields__: []
      }
    }
  })

  rpc(:ActionA, Example.ValuePayload, Example.SomeQueryResponse, %{})
end

defmodule Example.Actors.ExampleActor.Stub do
  use GRPC.Stub, service: Example.Actors.ExampleActor.Service
end

defmodule Example.Actors.ExampleActor.ActorDispatcher do
  use GRPC.Server, service: Example.Actors.ExampleActor.Service, http_transcode: true

  alias Sidecar.GRPC.Dispatcher

  @spec example_view(Example.ValuePayload.t(), GRPC.Server.Stream.t()) ::
          Example.SomeQueryResponse.t()
  def example_view(message, stream) do
    request = %{
      system: "spawn-system",
      actor_name: "ExampleActor",
      action_name: "ExampleView",
      input: message,
      stream: stream,
      descriptor: Example.Actors.ExampleActor.Service.descriptor()
    }

    Dispatcher.dispatch(request)
  end

  @spec action_a(Example.ValuePayload.t(), GRPC.Server.Stream.t()) ::
          Example.SomeQueryResponse.t()
  def action_a(message, stream) do
    request = %{
      system: "spawn-system",
      actor_name: "ExampleActor",
      action_name: "ActionA",
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
      Spawn.Actors.Healthcheck.HealthCheckActor.ActorDispatcher
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
  Invokes the ExampleView method registered on ExampleActor.

  ## Parameters
  - `ref` - The actor ref to send the action to.
  - `payload` - The payload to send to the action.
  - `opts` - The options to pass to the action.

  ## Examples
  ```elixir
  iex> Example.Actors.ExampleActor.example_view(%SpawnSdk.ActorRef{name: "actor_id_01", system: "spawn-system"}, %Example.ValuePayload{}, async: false, metadata: %{"example" => "metadata"})
  {:ok, %Example.SomeQueryResponse{}}
  ```
  """
  def example_view() do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ExampleActor"}
    |> example_view(%Example.ValuePayload{}, [])
  end

  def example_view(%Example.ValuePayload{} = payload) do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ExampleActor"}
    |> example_view(payload, [])
  end

  def example_view(%Example.ValuePayload{} = payload, opts) when is_list(opts) do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ExampleActor"}
    |> example_view(payload, opts)
  end

  def example_view(%SpawnSdk.ActorRef{} = ref, %Example.ValuePayload{} = payload) do
    ref
    |> example_view(payload, [])
  end

  def example_view(%SpawnSdk.ActorRef{} = ref, %Example.ValuePayload{} = payload, opts)
      when is_list(opts) do
    opts = [
      system: ref.system || "spawn-system",
      action: "ExampleView",
      payload: payload,
      async: opts[:async] || false,
      metadata: opts[:metadata] || %{}
    ]

    actor_to_invoke = ref.name || "ExampleActor"

    opts =
      if actor_to_invoke == "ExampleActor" do
        opts
      else
        Keyword.put(opts, :ref, "ExampleActor")
      end

    SpawnSdk.invoke(actor_to_invoke, opts)
  end

  @doc """
  Invokes the ActionA method registered on ExampleActor.

  ## Parameters
  - `ref` - The actor ref to send the action to.
  - `payload` - The payload to send to the action.
  - `opts` - The options to pass to the action.

  ## Examples
  ```elixir
  iex> Example.Actors.ExampleActor.action_a(%SpawnSdk.ActorRef{name: "actor_id_01", system: "spawn-system"}, %Example.ValuePayload{}, async: false, metadata: %{"example" => "metadata"})
  {:ok, %Example.SomeQueryResponse{}}
  ```
  """
  def action_a() do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ExampleActor"}
    |> action_a(%Example.ValuePayload{}, [])
  end

  def action_a(%Example.ValuePayload{} = payload) do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ExampleActor"}
    |> action_a(payload, [])
  end

  def action_a(%Example.ValuePayload{} = payload, opts) when is_list(opts) do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ExampleActor"}
    |> action_a(payload, opts)
  end

  def action_a(%SpawnSdk.ActorRef{} = ref, %Example.ValuePayload{} = payload) do
    ref
    |> action_a(payload, [])
  end

  def action_a(%SpawnSdk.ActorRef{} = ref, %Example.ValuePayload{} = payload, opts)
      when is_list(opts) do
    opts = [
      system: ref.system || "spawn-system",
      action: "ActionA",
      payload: payload,
      async: opts[:async] || false,
      metadata: opts[:metadata] || %{}
    ]

    actor_to_invoke = ref.name || "ExampleActor"

    opts =
      if actor_to_invoke == "ExampleActor" do
        opts
      else
        Keyword.put(opts, :ref, "ExampleActor")
      end

    SpawnSdk.invoke(actor_to_invoke, opts)
  end
end
