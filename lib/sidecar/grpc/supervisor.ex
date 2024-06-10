defmodule Sidecar.GRPC.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config
  alias Sidecar.GRPC.CodeGenerator, as: Generator

  def init(opts) do
    Logger.debug("Parser and compiling Protocol Buffers...")

    children =
      with {:compiling_protos, :ok} <-
             {:compiling_protos, Generator.compile_protos()},
           {:load_modules, {:ok, modules}} <- {:load_modules, Generator.load_modules(opts)},
           {:compiling_modules, :ok} <- {:compiling_modules, Generator.compile_modules(modules)} do
        children =
          []
          |> maybe_start_reflection(Config.get(:grpc_reflection_enabled))
          |> maybe_start_grpc_server(Config.get(:grpc_server_enabled))
      else
        {:compiling_protos, {:ok, :nothing_to_compile}} ->
          []

        {:compiling_protos, error} ->
          raise ArgumentError,
                "Failed during compilation of ActorHost Protobufs files. Details: #{inspect(error)}"

        {:load_modules, error} ->
          raise ArgumentError,
                "Failed on load of ActorHost Protobufs modules. Details: #{inspect(error)}"

        {:compiling_modules, error} ->
          raise ArgumentError,
                "Failed during compilation of ActorHost protobufs modules. Details: #{inspect(error)}"

        error ->
          raise ArgumentError,
                "Failed to load ActorHost Protobufs modules. Details: #{inspect(error)}"
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp maybe_start_reflection(children, false), do: children

  defp maybe_start_reflection(children, true) do
    Logger.info("Starting gRPC Reflection...")
    (children ++ [{GrpcReflection, []}]) |> List.flatten()
  end

  defp maybe_start_grpc_server(children, false), do: children

  defp maybe_start_grpc_server(children, true) do
    port = Config.get(:grpc_port)
    Logger.debug("Starting gRPC Server on port #{inspect(port)}...")

    (children ++
       [
         {GRPC.Server.Supervisor,
          endpoint: Sidecar.GRPC.ProxyEndpoint, port: port, start_server: true}
       ])
    |> List.flatten()
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
