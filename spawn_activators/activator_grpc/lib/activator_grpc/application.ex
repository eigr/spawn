defmodule ActivatorGRPC.Application do
  @moduledoc false

  use Application

  alias Actors.Config.Vapor, as: Config
  alias ActivatorGrpc.Api.Discovery
  alias ActivatorGrpc.GrpcServer, as: Server

  import Activator, only: [get_http_port: 1]

  @impl true
  def start(_type, _args) do
    config = Config.load(__MODULE__)

    builders = [
      %{
        service_name: "io.eigr.spawn.example.TestService",
        protocol: "grpc",
        system: "spawn-system",
        actor: "joe",
        options: %{
          # valids are: "invoke", "spawn-invoke"
          invocation_type: "invoke",
          pooled: false,
          timeout: 30_000,
          async: false,
          stream_out_from_channel: "my-channel",
          authentication: %{
            # valids are :none, basic, token
            kind: "basic",
            secret_key: ""
          }
        }
      }
    ]

    route_config = %{
      endpoint_builders: builders,
      proto_file_path: "priv/example/out/user-api.desc",
      proto: nil
    }

    grpc_server_spec =
      case Discovery.discover(route_config) do
        {:ok, descriptors, endpoints} ->
          Server.child_spec(descriptors, endpoints)

        error ->
          raise ArgumentError, "Unable to start the application #{inspect(error)}"
      end

    children = [
      Spawn.Supervisor.child_spec(config),
      {Bandit, plug: ActivatorGRPC.Router, scheme: :http, options: [port: get_http_port(config)]},
      Actors.Supervisors.ActorSupervisor.child_spec(config),
      grpc_server_spec
    ]

    opts = [strategy: :one_for_one, name: ActivatorGRPC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
