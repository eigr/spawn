defmodule SpawnCli.Commands.Dev.Run do
  use DoIt.Command,
    name: "run",
    description: "Run Spawn proxy in dev mode."

  alias SpawnCli.Util.Emoji

  import SpawnCli.Util, only: [log: 3]

  option(:actor_system, :string, "Defines the name of the ActorSystem.",
    alias: :s,
    default: "spawn-system"
  )

  option(:proto_definitions, :string, "Local where your protobuf files reside.",
    alias: :P,
    default: "./priv/protos"
  )

  option(:proxy_bind_address, :string, "Defines the proxy host address.",
    alias: :ba,
    default: "0.0.0.0"
  )

  option(:proxy_bind_port, :integer, "Defines the proxy host port.",
    alias: :bp,
    default: 9001
  )

  option(:proxy_image, :string, "Defines the proxy image.",
    alias: :I,
    default: "eigr/spawn-proxy:1.4.1"
  )

  option(:actor_host_port, :integer, "Defines the ActorHost (your program) port.",
    alias: :ap,
    default: 8090
  )

  option(:database_self_provisioning, :boolean, "Auto provisioning a local Database.",
    alias: :S,
    default: true
  )

  option(:database_host, :boolean, "Defines the Database hostname.",
    alias: :dh,
    default: false
  )

  option(:database_port, :integer, "Defines the Database port number.",
    alias: :dp,
    default: 3307
  )

  option(:database_type, :string, "Defines the Database provider.",
    alias: :dt,
    default: "mariadb"
  )

  option(:database_pool, :integer, "Defines the Database pool size.",
    alias: :dP,
    default: 30
  )

  option(:statestore_key, :string, "Defines the Statestore Key.",
    alias: :K,
    keep: false
  )

  option(:log_level, :string, "Defines the Logger level.",
    alias: :L,
    default: "info"
  )

  option(:name, :string, "Defines the name of the Proxy instance.",
    alias: :n,
    default: "proxy"
  )

  option(:enable_nats, :boolean, "Use or not Nats for cross ActorSystem communication",
    alias: :N,
    default: false
  )

  def run(_, %{actor_system: system, proxy_image: proxy_image} = opts, _context) do
    log(:info, Emoji.runner(), "Starting Spawn Proxy in dev mode...")
    {:ok, info} = Testcontainers.start_link()

    proxy_container_config = %Testcontainers.Container{
      image: proxy_image
      # wait_strategies: [
      #   %Testcontainers.PortWaitStrategy{
      #     ip: opts.proxy_bind_address,
      #     port: opts.proxy_bind_port,
      #     timeout: 20000
      #   }
      # ]
    }

    case Testcontainers.start_container(proxy_container_config) do
      {:ok, container} ->
        IO.inspect(container)

        log(
          :info,
          Emoji.check(),
          "Spawn Proxy started successfuly in dev mode. Container Id: #{container.container_id}"
        )

        System.at_exit(fn status ->
          Testcontainers.stop_container(container.container_id)

          log(
            :info,
            Emoji.winking(),
            "Stopping Spawn Proxy in dev mode with status: #{inspect(status)}. Container Id: #{container.container_id}"
          )
        end)

        Process.sleep(:infinity)

      error ->
        log(
          :error,
          Emoji.tired_face(),
          "Failure occurring during Spawn Proxy start phase. Details: #{inspect(error)}"
        )
    end
  end
end
