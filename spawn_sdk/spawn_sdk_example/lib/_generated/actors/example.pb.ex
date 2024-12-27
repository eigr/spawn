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
                    pattern: {:post, "/v1/example/sum"},
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
          options: %Google.Protobuf.ServiceOptions{
            deprecated: false,
            uninterpreted_option: [],
            __pb_extensions__: %{
              {Spawn.Actors.PbExtension, :actor} => %Spawn.Actors.ActorOpts{
                state_type: ".example.ExampleState",
                stateful: true,
                deactivate_timeout: 3000,
                snapshot_interval: 60000,
                sourceable: false,
                strict_events_ordering: false,
                events_retention_strategy: nil,
                subjects: [],
                kind: :NAMED,
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
            span: [0, 0, 30, 1],
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
            span: [8, 0, 30, 1],
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
            span: [9, 2, 15, 4],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 3, 4_890_128],
            span: [9, 2, 15, 4],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0],
            span: [17, 2, 22, 3],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 1],
            span: [17, 6, 17],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 2],
            span: [17, 19, 40],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 3],
            span: [17, 51, 77],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4],
            span: [18, 4, 21, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4, 4_890_127],
            span: [18, 4, 21, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1],
            span: [24, 2, 29, 3],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 1],
            span: [24, 6, 9],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 2],
            span: [24, 11, 32],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 3],
            span: [24, 43, 63],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 4],
            span: [25, 4, 28, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 1, 4, 72_295_728],
            span: [25, 4, 28, 6],
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

  rpc(:Sum, Example.ValuePayload, Example.SumResponse, %{
    http: %{
      type: Google.Api.PbExtension,
      value: %Google.Api.HttpRule{
        selector: "",
        body: "*",
        additional_bindings: [],
        response_body: "",
        pattern: {:post, "/v1/example/sum"},
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
  Invokes the get_state implicit action for this actor.

  ## Examples
  ```elixir
  iex> Example.Actors.ExampleActor.get_state()
  {:ok, actor_state}
  ```
  """
  def get_state do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ExampleActor"}
    |> get_state()
  end

  @doc """
  Invokes the get_state implicit action.

  ## Parameters
  - `ref` - The actor ref to send the action to.

  ## Examples
  ```elixir
  iex> Example.Actors.ExampleActor.get_state(%SpawnSdk.ActorRef{name: "actor_id_01", system: "spawn-system"})
  {:ok, actor_state}
  ```
  """
  def get_state(%SpawnSdk.ActorRef{} = ref) do
    opts = [
      system: ref.system || "spawn-system",
      action: "get_state",
      async: false
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
  Invokes the Sum method registered on ExampleActor.

  ## Parameters
  - `ref` - The actor ref to send the action to.
  - `payload` - The payload to send to the action.
  - `opts` - The options to pass to the action.

  ## Examples
  ```elixir
  iex> Example.Actors.ExampleActor.sum(%SpawnSdk.ActorRef{name: "actor_id_01", system: "spawn-system"}, %Example.ValuePayload{}, async: false, metadata: %{"example" => "metadata"})
  {:ok, %Example.SumResponse{}}
  ```
  """
  def sum() do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ExampleActor"}
    |> sum(%Example.ValuePayload{}, [])
  end

  def sum(%Example.ValuePayload{} = payload) do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ExampleActor"}
    |> sum(payload, [])
  end

  def sum(%Example.ValuePayload{} = payload, opts) when is_list(opts) do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ExampleActor"}
    |> sum(payload, opts)
  end

  def sum(%SpawnSdk.ActorRef{} = ref, %Example.ValuePayload{} = payload) do
    ref
    |> sum(payload, [])
  end

  def sum(%SpawnSdk.ActorRef{} = ref, %Example.ValuePayload{} = payload, opts)
      when is_list(opts) do
    opts = [
      system: ref.system || "spawn-system",
      action: "Sum",
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
