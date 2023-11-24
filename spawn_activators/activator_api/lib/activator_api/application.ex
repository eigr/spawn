defmodule ActivatorAPI.Application do
  @moduledoc false

  use Application

  alias Actors.Config.PersistentTermConfig, as: Config
  alias ActivatorAPI.Api.Discovery
  alias ActivatorAPI.GrpcServer, as: Server

  import Activator, only: [get_http_port: 1]

  @impl true
  def start(_type, _args) do
    Config.load()

    children =
      [
        Activator.Supervisor.child_spec([]),
        {Bandit, plug: ActivatorAPI.Router, scheme: :http, port: get_http_port()}
      ]
      |> put_grpc_server()

    opts = [strategy: :one_for_one, name: ActivatorAPI.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp put_grpc_server(children) do
    builders = [
      %{
        service_name: "io.eigr.spawn.example.TestService",
        protocol: "grpc",
        system: "spawn-system",
        actor: "joe",
        action: "sum",
        parent_actor: nil,
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
      # %{
      #   service_name: "io.eigr.spawn.example.TestService",
      #   protocol: "grpc",
      #   system: "spawn-system",
      #   actor: "robert",
      #   action: "sum",
      #   parent_actor: "unamed_actor",
      #   options: %{
      #     # valids are: "invoke", "spawn-invoke"
      #     invocation_type: "spawn-invoke",
      #     pooled: false,
      #     timeout: 30_000,
      #     async: false,
      #     stream_out_from_channel: "my-channel",
      #     authentication: %{
      #       # valids are :none, basic, token
      #       kind: "basic",
      #       secret_key: ""
      #     }
      #   }
      # }
    ]

    route_config = %{
      endpoint_builders: builders,
      proto_file_path: "priv/example/out/user-api.desc",
      proto: nil
    }

    case Discovery.discover(route_config) do
      {:ok, descriptors, endpoints} ->
        children ++ [Server.child_spec(descriptors, endpoints)]

      error ->
        raise ArgumentError, "Unable to start the application #{inspect(error)}"
    end
  end
end
