defmodule ActivatorGrpc.Api.Dispatcher do
  @moduledoc """
  Dispatch behaviour to requests gRPC requests to Actor Actions.
  """

  @type message :: any()

  @type stream :: GRPC.Server.Stream.t()

  @type opts :: [
          action: String.t(),
          actor_name: String.t(),
          async: String.t() | boolean(),
          authentication_kind: String.t(),
          authentication_secret: String.t(),
          service_name: String.t(),
          original_method: String.t(),
          system_name: String.t(),
          system_name: String.t(),
          invocation_type: String.t(),
          request_type: String.t(),
          input_type: String.t(),
          output_type: String.t(),
          pooled: String.t() | boolean(),
          timeout: non_neg_integer(),
          stream_out_from_channel: String.t()
        ]

  @doc """


  ```
  [
    service_name: "io.eigr.spawn.example.TestService",
    original_method: "Sum",
    actor_name: "joe",
    action: "sum"
    system_name: "spawn-system",
    invocation_type: "invoke",
    request_type: "unary",
    input_type: Io.Eigr.Spawn.Example.MyBusinessMessage,
    output_type: Io.Eigr.Spawn.Example.MyBusinessMessage,
    pooled: "false",
    timeout: "30000",
    async: "false",
    stream_out_from_channel: "my-channel",
    authentication_kind: "basic",
    authentication_secret: ""
  ]
  ```
  """
  @callback dispatch(message(), stream(), opts()) :: any()
end
