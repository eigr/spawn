defmodule Sidecar.GRPC.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config
  alias Sidecar.GRPC.CodeGenerator, as: Generator

  def init(opts) do
    Logger.info("Starting gRPC Server...")

    with :ok <- Generator.compile_protos(),
         {:ok, modules} <- Generator.load_modules(opts),
         :ok <- Generator.compile_modules(modules) do
      children = [
        {GrpcReflection, []},
        {GRPC.Server.Supervisor,
         endpoint: Sidecar.GRPC.ProxyEndpoint, port: Config.get(:grpc_port), start_server: true}
      ]

      Supervisor.init(children, strategy: :one_for_one)
    else
      error ->
        raise ArgumentError,
              "Failed to load ActorHost protobufs modules. Details: #{inspect(error)}"
    end
  end

  def start_link(opts) do
    Supervisor.start_link(
      __MODULE__,
      opts,
      name: __MODULE__,
      strategy: :one_for_one
    )
  end
end
