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
    entities = [%{service_name: "io.eigr.spawn.example.TestService"}]

    route_config = %{
      entities: entities,
      proto_file_path: "priv/example/out/user-api.desc",
      proto: nil
    }

    {:ok, descriptors, endpoints} = Discovery.discover(route_config)
    grpc_server_spec = Server.child_spec(descriptors, endpoints)

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
