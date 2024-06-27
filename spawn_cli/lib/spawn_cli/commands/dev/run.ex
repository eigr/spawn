defmodule SpawnCli.Commands.Dev.Run do
  @moduledoc """
  Command module to run the Spawn proxy in development mode.

  ## Examples

  ### Example 1: Running with Default Options

   ```
    > spawnctl dev run
   ```

  This will start the proxy with the following default settings:

  - ActorSystem name: "spawn-system"
  - Protobuf files location: "/fakepath"
  - Proxy bind address: "0.0.0.0"
  - Proxy bind port: 9001
  - Proxy image: "eigr/spawn-proxy:1.4.1"
  - ActorHost port: 8090
  - Auto provisioning a local Database: true
  - Database hostname: "mariadb"
  - Database port: 3307
  - Database provider: "mariadb"
  - Database pool size: 30
  - Statestore Key: "myfake-key-3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE="
  - Logger level: "info"
  - Proxy instance name: "proxy"
  - Use Nats for cross ActorSystem communication: false

  ### Example 2: Running with Custom Actor System and Database Host

  ```
  > spawnctl dev run --actor-system "custom-system" --database-host "localhost"
  ```

  This will start the proxy with a custom ActorSystem name and Database hostname:

  - ActorSystem name: "custom-system"
  - Database hostname: "localhost"

  Other options will use their default values.

  ### Example 3: Running with Custom Proxy Bind Address and Port

  ```
  > spawnctl dev run --proxy-bind-address "192.168.1.1" --proxy-bind-port 8080
  ```

  This will start the proxy with a custom bind address and port:

  - Proxy bind address: "192.168.1.1"
  - Proxy bind port: 8080

  Other options will use their default values.

  ### Example 4: Running with All Custom Options

  ```
  > spawnctl dev run --actor-system "custom-system" \
      --proto-files "/myprotos" \
      --proxy-bind-address "192.168.1.1" \
      --proxy-bind-port 8080 \
      --proxy-image "custom/proxy:latest" \
      --actor-host-port 9090 \
      --database-self-provisioning false \
      --database-host "localhost" \
      --database-port 5432 \
      --database-type "postgres" \
      --database-pool 50  \
      --statestore-key "custom-key" \
      --log-level "debug" \
      --enable-nats true \
      --name "custom-proxy"
  ```
  """
  use DoIt.Command,
    name: "run",
    description: "Run Spawn proxy in dev mode."

  alias SpawnCli.Util.Emoji
  alias Testcontainers.Container

  import SpawnCli.Util, only: [log: 3]

  @default_opts %{
    actor_system: "spawn-system",
    proto_files: "/fakepath",
    proto_changes_watcher: false,
    proxy_bind_address: "0.0.0.0",
    proxy_bind_port: 9001,
    proxy_bind_grpc_port: 9081,
    proxy_image: "eigr/spawn-proxy:1.4.1",
    actor_host_port: 8090,
    database_self_provisioning: true,
    database_host: "mariadb",
    database_port: 3307,
    database_type: "mariadb",
    database_pool: 30,
    statestore_key: "myfake-key-3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE=",
    log_level: "info",
    name: "proxy",
    enable_nats: false
  }

  option(:actor_system, :string, "Defines the name of the ActorSystem.",
    alias: :s,
    default: @default_opts.actor_system
  )

  option(:proto_files, :string, "Local where your protobuf files reside.",
    alias: :P,
    default: @default_opts.proto_files
  )

  option(:proto_changes_watcher, :boolean, "Watches changes in protobuf files and reload proxy.",
    alias: :W,
    default: @default_opts.proto_changes_watcher
  )

  option(:proxy_bind_address, :string, "Defines the proxy host address.",
    alias: :ba,
    default: @default_opts.proxy_bind_address
  )

  option(:proxy_bind_port, :integer, "Defines the proxy host port.",
    alias: :bp,
    default: @default_opts.proxy_bind_port
  )

  option(:proxy_bind_grpc_port, :integer, "Defines the proxy gRPC host port.",
    alias: :bp,
    default: @default_opts.proxy_bind_grpc_port
  )

  option(:proxy_image, :string, "Defines the proxy image.",
    alias: :I,
    default: @default_opts.proxy_image
  )

  option(:actor_host_port, :integer, "Defines the ActorHost (your program) port.",
    alias: :ap,
    default: @default_opts.actor_host_port
  )

  option(:database_self_provisioning, :boolean, "Auto provisioning a local Database.",
    alias: :S,
    default: @default_opts.database_self_provisioning
  )

  option(:database_host, :string, "Defines the Database hostname.",
    alias: :dh,
    default: @default_opts.database_host
  )

  option(:database_port, :integer, "Defines the Database port number.",
    alias: :dp,
    default: @default_opts.database_port
  )

  option(:database_type, :string, "Defines the Database provider.",
    alias: :dt,
    default: @default_opts.database_type
  )

  option(:database_pool, :integer, "Defines the Database pool size.",
    alias: :dP,
    default: @default_opts.database_pool
  )

  option(:statestore_key, :string, "Defines the Statestore Key.",
    alias: :K,
    default: @default_opts.statestore_key
  )

  option(:log_level, :string, "Defines the Logger level.",
    alias: :L,
    default: @default_opts.log_level
  )

  option(:name, :string, "Defines the name of the Proxy instance.",
    alias: :n,
    default: @default_opts.name
  )

  option(:enable_nats, :boolean, "Use or not Nats for cross ActorSystem communication",
    alias: :N,
    default: @default_opts.enable_nats
  )

  @doc """
  Runs the Spawn proxy in development mode.

  This function starts the Spawn proxy container with the provided options.
  """
  def run(_, opts, _context) do
    log(:info, Emoji.runner(), "Starting Spawn Proxy in dev mode...")
    {:ok, _status} = Testcontainers.start_link()

    build_proxy_container(opts)
    |> Testcontainers.start_container()
    |> case do
      {:ok, container} ->
        log_success(container, opts.proxy_bind_port, opts.database_port)
        setup_exit_handler(container)

        if opts.proto_changes_watcher do
          {:ok, pid} = FileSystem.start_link(dirs: [opts.proto_files])
          FileSystem.subscribe(pid)
          watch(container, opts)
        else
          Process.sleep(:infinity)
        end

      error ->
        log_failure(error)
    end
  end

  defp watch(container, opts) do
    receive do
      {:file_event, worker_pid, {path, events}} = evt ->
        IO.inspect(evt, label: "File Watcher event")
        watch(container, opts)

      other ->
        watch(container, opts)
    end
  end

  defp build_proxy_container(opts) do
    Container.new(opts.proxy_image)
    |> Container.with_environment("PROXY_CLUSTER_STRATEGY", "gossip")
    |> Container.with_environment("PROXY_DATABASE_TYPE", opts.database_type)
    |> Container.with_environment("PROXY_DATABASE_PORT", "#{opts.database_port}")
    |> Container.with_environment("PROXY_DATABASE_POOL_SIZE", "#{opts.database_pool}")
    |> Container.with_environment("PROXY_HTTP_PORT", "#{opts.proxy_bind_port}")
    |> Container.with_environment("SPAWN_USE_INTERNAL_NATS", "#{opts.enable_nats}")
    |> Container.with_environment("SPAWN_PROXY_LOGGER_LEVEL", opts.log_level)
    |> Container.with_environment("SPAWN_STATESTORE_KEY", opts.statestore_key)
    |> Container.with_environment("USER_FUNCTION_PORT", "#{opts.actor_host_port}")
    |> Container.with_exposed_ports([opts.proxy_bind_port, opts.database_port])
    |> Container.with_label("spawn.actorsystem.name", opts.actor_system)
    |> Container.with_label("spawn.proxy.name", opts.name)
    |> Container.with_label("spawn.proxy.database.type", opts.database_type)
    |> Container.with_label("spawn.proxy.logger.level", opts.log_level)
    #|> maybe_put_proto_files(opts.proto_files)
  end

  defp maybe_put_proto_files(container, "/fakepath"), do: container

  defp maybe_put_proto_files(container, protopath) do
    container
    |> Container.with_bind_mount("PROXY_CLUSTER_STRATEGY", protopath)
  end

  defp log_success(container, proxy_bind_port, database_port) do
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
  end

  defp log_failure(error) do
    log(
      :error,
      Emoji.tired_face(),
      "Failure occurring during Spawn Proxy start phase. Details: #{inspect(error)}"
    )
  end

  defp setup_exit_handler(container) do
    System.at_exit(fn status ->
      Testcontainers.stop_container(container.container_id)

      log(
        :info,
        Emoji.winking(),
        "Stopping Spawn Proxy in dev mode with status: #{inspect(status)}. Container Id: #{container.container_id}"
      )
    end)
  end
end
