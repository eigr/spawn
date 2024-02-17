defmodule Sidecar.GRPC.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Sidecar.GRPC.CodeGenerator, as: Generator

  def init(opts) do
    Logger.info("Starting gRPC Server...")
    Application.put_env(:grpc, :start_server, true, persistent: true)

    case Generator.compile_protos() do
      :ok ->
        Generator.load_modules(opts)
        |> Generator.compile_modules()

      error ->
        raise ArgumentError,
              "Failed to load ActorHost protobufs modules. Details: #{inspect(error)}"
    end

    children = []

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
