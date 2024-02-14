defmodule Proxy.Grpc.Supervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Proxy.Grpc.CodeGenerator, as: GrpcGenerator

  def init(opts) do
    Logger.info("Starting gRPC Server...")
    Application.put_env(:grpc, :start_server, true, persistent: true)

    descriptor = Keyword.fetch!(:file_descriptor)
    actors = Keyword.fetch!(:actors)

    children =
      descriptor
      |> GrpcGenerator.compile(actors)
      |> GrpcGenerator.build_spec()
      |> maybe_start_reflection(descriptor)

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp maybe_start_reflection(children, descriptor) do
    [children] ++ [{Proxy.Grpc.Reflection, [descriptor]}]
  end
end
