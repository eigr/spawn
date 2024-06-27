defmodule SpawnCli.Commands.Dev.Run do
  use DoIt.Command,
    name: "run",
    description: "Run Spawn proxy in dev mode."

  alias SpawnCli.Util.Emoji
  alias Testcontainers.Container

  import SpawnCli.Util, only: [log: 3]

  option(:actor_system, :string, "Defines the name of the ActorSystem.",
    alias: :s,
    default: "spawn-system"
  )

  option(:proto_definitions, :string, "Local where your protobuf files reside.",
    alias: :P,
    default: "/fakepath"
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

  option(:database_host, :string, "Defines the Database hostname.",
    alias: :dh,
    default: "mariadb"
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
    default: "myfake-key-3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE="
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

  def run(
        _,
        %{
          actor_host_port: actor_host_port,
          actor_system: actor_system,
          database_host: database_host,
          database_pool: database_pool,
          database_port: database_port,
          database_self_provisioning: database_self_provisioning,
          database_type: database_type,
          enable_nats: enable_nats,
          log_level: log_level,
          name: name,
          proto_definitions: proto_definitions,
          proxy_bind_address: proxy_bind_address,
          proxy_bind_port: proxy_bind_port,
          proxy_image: proxy_image,
          statestore_key: statestore_key
        } =
          opts,
        _context
      ) do
    log(:info, Emoji.runner(), "Starting Spawn Proxy in dev mode...")
    {:ok, info} = Testcontainers.start_link()

    proxy_container_config =
      Container.new(proxy_image)
      |> Container.with_environment("PROXY_CLUSTER_STRATEGY", "gossip")
      |> Container.with_environment("PROXY_DATABASE_TYPE", database_type)
      |> Container.with_environment("PROXY_DATABASE_PORT", "#{database_port}")
      |> Container.with_environment("PROXY_DATABASE_POOL_SIZE", "#{database_pool}")
      |> Container.with_environment("PROXY_HTTP_PORT", "#{proxy_bind_port}")
      |> Container.with_environment("SPAWN_USE_INTERNAL_NATS", "#{enable_nats}")
      |> Container.with_environment("SPAWN_PROXY_LOGGER_LEVEL", log_level)
      |> Container.with_environment("SPAWN_STATESTORE_KEY", statestore_key)
      |> Container.with_environment("USER_FUNCTION_PORT", "#{actor_host_port}")
      |> Container.with_exposed_ports([proxy_bind_port, database_port])
      |> Container.with_label("spawn.actorsystem.name", actor_system)
      |> Container.with_label("spawn.proxy.name", name)
      |> Container.with_label("spawn.proxy.database.type", database_type)
      |> Container.with_label("spawn.proxy.logger.level", log_level)
      |> maybe_put_proto_definitions(proto_definitions)

    case Testcontainers.start_container(proxy_container_config) do
      {:ok, container} ->
        log(
          :info,
          Emoji.floppy_disk(),
          "Spawn Proxy uses the following mapped ports: [
      Proxy: #{inspect(Container.mapped_port(container, proxy_bind_port))}:#{proxy_bind_port},
      Database: #{inspect(Container.mapped_port(container, database_port))}:#{database_port}
    ]"
        )

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

  defp maybe_put_proto_definitions(container, "/fakepath"), do: container

  defp maybe_put_proto_definitions(container, protopath) do
    container
    |> Container.with_bind_mount("PROXY_CLUSTER_STRATEGY", protopath)
  end
end
