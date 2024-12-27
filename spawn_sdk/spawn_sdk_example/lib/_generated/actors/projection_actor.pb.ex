defmodule Example.Actors.ProjectionActor.Service do
  use GRPC.Service, name: "example.actors.ProjectionActor", protoc_gen_elixir_version: "0.13.0"

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.FileDescriptorProto{
      name: "actors/projection_actor.proto",
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
          name: "ProjectionActor",
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
            }
          ],
          options: %Google.Protobuf.ServiceOptions{
            deprecated: false,
            uninterpreted_option: [],
            __pb_extensions__: %{
              {Spawn.Actors.PbExtension, :actor} => %Spawn.Actors.ActorOpts{
                state_type: ".example.ExampleState",
                stateful: true,
                deactivate_timeout: 999_999_999,
                snapshot_interval: 60000,
                sourceable: false,
                strict_events_ordering: false,
                events_retention_strategy: %Spawn.Actors.EventsRetentionStrategy{
                  strategy: {:duration_ms, 86000},
                  __unknown_fields__: []
                },
                subjects: [
                  %Spawn.Actors.ProjectionSubject{
                    actor: "ClockActor",
                    action: "Clock",
                    start_time: nil,
                    __unknown_fields__: []
                  }
                ],
                kind: :PROJECTION,
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
            span: [8, 8, 23],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 3],
            span: [9, 2, 22, 4],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 3, 4_890_128],
            span: [9, 2, 22, 4],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0],
            span: [24, 2, 29, 3],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 1],
            span: [24, 6, 17],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 2],
            span: [24, 19, 40],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 3],
            span: [24, 51, 77],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4],
            span: [25, 4, 28, 6],
            leading_comments: nil,
            trailing_comments: nil,
            leading_detached_comments: [],
            __unknown_fields__: []
          },
          %Google.Protobuf.SourceCodeInfo.Location{
            path: [6, 0, 2, 0, 4, 4_890_127],
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
end

defmodule Example.Actors.ProjectionActor.Stub do
  use GRPC.Stub, service: Example.Actors.ProjectionActor.Service
end

defmodule Example.Actors.ProjectionActor.ActorDispatcher do
  use GRPC.Server, service: Example.Actors.ProjectionActor.Service, http_transcode: true

  alias Sidecar.GRPC.Dispatcher

  @spec example_view(Example.ValuePayload.t(), GRPC.Server.Stream.t()) ::
          Example.SomeQueryResponse.t()
  def example_view(message, stream) do
    request = %{
      system: "spawn-system",
      actor_name: "ProjectionActor",
      action_name: "ExampleView",
      input: message,
      stream: stream,
      descriptor: Example.Actors.ProjectionActor.Service.descriptor()
    }

    Dispatcher.dispatch(request)
  end
end

defmodule Example.Actors.ProjectionActor do
  @moduledoc "This module provides helper functions for invoking the methods on the Example.Actors.ProjectionActor actor."

  @doc """
  Invokes the get_state implicit action for this actor.

  ## Examples
  ```elixir
  iex> Example.Actors.ProjectionActor.get_state()
  {:ok, actor_state}
  ```
  """
  def get_state do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ProjectionActor"}
    |> get_state()
  end

  @doc """
  Invokes the get_state implicit action.

  ## Parameters
  - `ref` - The actor ref to send the action to.

  ## Examples
  ```elixir
  iex> Example.Actors.ProjectionActor.get_state(SpawnSdk.Actor.ref("spawn-system", "actor_id_01"))
  {:ok, actor_state}
  ```
  """
  def get_state(%SpawnSdk.ActorRef{} = ref) do
    opts = [
      system: ref.system || "spawn-system",
      action: "get_state",
      async: false
    ]

    actor_to_invoke = ref.name || "ProjectionActor"

    opts =
      if actor_to_invoke == "ProjectionActor" do
        opts
      else
        Keyword.put(opts, :ref, "ProjectionActor")
      end

    SpawnSdk.invoke(actor_to_invoke, opts)
  end

  def example_view() do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ProjectionActor"}
    |> example_view(%Example.ValuePayload{}, [])
  end

  def example_view(%Example.ValuePayload{} = payload) do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ProjectionActor"}
    |> example_view(payload, [])
  end

  def example_view(%Example.ValuePayload{} = payload, opts) when is_list(opts) do
    %SpawnSdk.ActorRef{system: "spawn-system", name: "ProjectionActor"}
    |> example_view(payload, opts)
  end

  def example_view(%SpawnSdk.ActorRef{} = ref, %Example.ValuePayload{} = payload) do
    ref
    |> example_view(payload, [])
  end

  @doc """
  Invokes the ExampleView method registered on ProjectionActor.

  ## Parameters
  - `ref` - The actor ref to send the action to.
  - `payload` - The payload to send to the action.
  - `opts` - The options to pass to the action.

  ## Examples
  ```elixir
  iex> Example.Actors.ProjectionActor.example_view(SpawnSdk.Actor.ref("spawn-system", "actor_id_01"), %Example.ValuePayload{}, async: false, metadata: %{"example" => "metadata"})
  {:ok, %Example.SomeQueryResponse{}}
  ```
  """
  def example_view(%SpawnSdk.ActorRef{} = ref, %Example.ValuePayload{} = payload, opts)
      when is_list(opts) do
    opts = [
      system: ref.system || "spawn-system",
      action: "ExampleView",
      payload: payload,
      async: opts[:async] || false,
      metadata: opts[:metadata] || %{}
    ]

    actor_to_invoke = ref.name || "ProjectionActor"

    opts =
      if actor_to_invoke == "ProjectionActor" do
        opts
      else
        Keyword.put(opts, :ref, "ProjectionActor")
      end

    SpawnSdk.invoke(actor_to_invoke, opts)
  end
end