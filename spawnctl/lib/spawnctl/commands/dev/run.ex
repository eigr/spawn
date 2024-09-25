defmodule SpawnCtl.Commands.Dev.Run do
  @moduledoc """
  Command module to run the Spawn proxy in development mode.

  ## Examples

  ### Example 1: Running with Default Options

      > spawnctl dev run

  This will start the proxy with the following default settings:

  - ActorSystem name: "spawn-system"
  - Protobuf files location: "/fakepath"
  - Proxy bind address: "0.0.0.0"
  - Proxy bind port: 9001
  - Proxy image: "ghcr.io/eigr/spawn-proxy:1.4.3"
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

      > spawnctl dev run --actor-system "custom-system" --database-host "localhost"

  This will start the proxy with a custom ActorSystem name and Database hostname:

  - ActorSystem name: "custom-system"
  - Database hostname: "localhost"

  Other options will use their default values.

  ### Example 3: Running with Custom Proxy Bind Address and Port

      > spawnctl dev run --proxy-bind-address "192.168.1.1" --proxy-bind-port 8080

  This will start the proxy with a custom bind address and port:

  - Proxy bind address: "192.168.1.1"
  - Proxy bind port: 8080

  Other options will use their default values.

  ### Example 4: Running with All Custom Options

      > spawnctl dev run --actor-system "custom-system" \
          --protos "./protos" \
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
  """
  use DoIt.Command,
    name: "run",
    description: "Run Spawn proxy in dev mode."

  alias SpawnCtl.Util.Emoji
  alias Testcontainers.Container

  import SpawnCtl.Util, only: [generate: 0, is_valid?: 1, log: 3]

  @default_opts %{
    actor_system: "spawn-system",
    manifest_path: ".k8s/",
    protos: "./protos",
    proto_changes_watcher: false,
    proxy_bind_address: "0.0.0.0",
    proxy_bind_port: 9001,
    proxy_bind_grpc_port: 9980,
    proxy_image: "ghcr.io/eigr/spawn-proxy:1.4.3",
    actor_host_port: 8090,
    database_self_provisioning: true,
    database_host: "",
    database_port: 0,
    database_type: "native",
    database_pool: 30,
    statestore_key: "3Jnb0hZiHIzHTOih7t2cTEPEpY98Tu1wvQkPfq/XwqE=",
    log_level: "info",
    name: "proxy",
    enable_nats: false
  }

  option(:actor_system, :string, "Defines the name of the ActorSystem.",
    alias: :s,
    default: @default_opts.actor_system
  )

  option(:manifest_path, :string, "Path where your Actor k8s manifest files reside.",
    alias: :M,
    default: @default_opts.manifest_path
  )

  option(:protos, :string, "Path where your protobuf files reside.",
    alias: :p,
    default: @default_opts.protos
  )

  option(:proto_changes_watcher, :boolean, "Watches changes in protobuf files and reload proxy.",
    alias: :W,
    default: @default_opts.proto_changes_watcher
  )

  option(:proxy_bind_address, :string, "Defines the proxy host address.",
    alias: :A,
    default: @default_opts.proxy_bind_address
  )

  option(:proxy_bind_port, :integer, "Defines the proxy host port.",
    alias: :P,
    default: @default_opts.proxy_bind_port
  )

  option(:proxy_bind_grpc_port, :integer, "Defines the proxy gRPC host port.",
    alias: :G,
    default: @default_opts.proxy_bind_grpc_port
  )

  option(:proxy_image, :string, "Defines the proxy image.",
    alias: :I,
    default: @default_opts.proxy_image
  )

  option(:actor_host_port, :integer, "Defines the ActorHost (your program) port.",
    alias: :H,
    default: @default_opts.actor_host_port
  )

  option(:database_self_provisioning, :boolean, "Auto provisioning a local Database.",
    alias: :S,
    default: @default_opts.database_self_provisioning
  )

  option(:database_host, :string, "Defines the Database hostname.",
    alias: :h,
    default: @default_opts.database_host
  )

  option(:database_port, :integer, "Defines the Database port number.",
    alias: :D,
    default: @default_opts.database_port
  )

  option(:database_type, :string, "Defines the Database provider.",
    alias: :T,
    default: @default_opts.database_type
  )

  option(:database_pool, :integer, "Defines the Database pool size.",
    alias: :O,
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
  def run(args, opts, ctx) do
    parent = self()

    {:ok, :quit} =
      System.trap_signal(:sigquit, :quit, fn ->
        send(parent, :exit)
        :ok
      end)

    spawn(fn -> do_run(args, opts, ctx) end)

    receive do
      :exit ->
        log(:info, Emoji.runner(), "[#{get_time()}] Stopping Spawn Proxy...")
        System.stop()
    end
  end

  defp do_run(_, opts, ctx) do
    log(:info, Emoji.runner(), "[#{get_time()}] Starting Spawn Proxy in dev mode...")

    if opts.proto_changes_watcher do
      paths =
        if File.exists?(opts.manifest_path),
          do: [opts.protos, opts.manifest_path],
          else: [opts.protos]

      {:ok, pid} = FileSystem.start_link(dirs: paths)
      FileSystem.subscribe(pid)
      watch(nil, opts, ctx)
    else
      case Testcontainers.start_link() do
        {:ok, _docker_pid} ->
          case start_container(opts, ctx) do
            {:ok, _container} ->
              Process.sleep(:infinity)

            {:error, error} ->
              log_failure(error)
              System.stop(1)
          end

        error ->
          log_failure(error)
          System.stop(1)
      end
    end
  end

  defp start_container(opts, _ctx) do
    opts
    |> parse_inputs()
    |> build_proxy_container()
    |> Testcontainers.start_container()
    |> handle_container_start_result(opts)
  end

  defp parse_inputs(opts) do
    opts
    |> Map.update!(:protos, &Path.absname/1)
    |> Map.update!(:manifest_path, &Path.absname/1)
  end

  defp handle_container_start_result({:ok, container}, opts) do
    :os.type()
    |> log_success(container, opts)

    setup_exit_handler(container)
    {:ok, container}
  end

  defp handle_container_start_result(error, _opts) do
    log_failure(error)
    {:error, error}
  end

  defp watch(nil, opts, ctx) do
    if opts[:docker_pid] == nil do
      with {:ok, docker_pid} <- Testcontainers.start_link(),
           {:ok, container} <- start_container(Map.put(opts, :docker_pid, docker_pid), ctx) do
        await_file_events(container, opts, ctx)
      else
        {:error, {:already_started, pid}} ->
          log(:info, Emoji.winking(), "Stopping docker setup...")
          stop_existing_docker_process(pid)
          watch(nil, opts, ctx)

        {:error, {:error, {:failed_to_register_ryuk_filter, :closed}}} ->
          log_transient_fault()
          watch(nil, opts, ctx)

        error ->
          log_failure(error)
      end
    else
      start_and_watch_container(opts, ctx)
    end
  end

  defp watch(container, opts, ctx), do: await_file_events(container, opts, ctx)

  defp await_file_events(container, opts, ctx) do
    receive do
      {:file_event, _worker_pid, {path, events}} = _evt ->
        main_evt = List.first(events)

        if is_valid?(path) && Enum.member?([:created, :modified, :deleted], main_evt) do
          log(
            :info,
            Emoji.floppy_disk(),
            "Detected #{inspect(List.first(events))} change in file [#{inspect(path)}]. Restarting Spawn proxy now..."
          )

          restart_container(container, opts, ctx)
        else
          watch(container, opts, ctx)
        end

      _other ->
        watch(container, opts, ctx)
    end
  end

  defp restart_container(container, opts, ctx) do
    Testcontainers.stop_container(container.container_id)
    Process.sleep(500)
    watch(nil, opts, ctx)
  end

  defp start_and_watch_container(opts, ctx) do
    with {:ok, container} <- start_container(opts, ctx) do
      await_file_events(container, opts, ctx)
    else
      {:error, {:already_started, pid}} ->
        log(:info, Emoji.winking(), "Stopping docker setup...")
        stop_existing_docker_process(pid)
        watch(nil, opts, ctx)

      {:error, {:error, :failed_to_register_ryuk_filter, :closed}} ->
        log_transient_fault()
        watch(nil, opts, ctx)

      {:error, error} ->
        log_failure(error)
        System.stop(1)

      error ->
        log_failure(error)
        System.stop(1)
    end
  end

  defp stop_existing_docker_process(pid) do
    Process.exit(pid, :normal)
    Process.sleep(500)
  end

  defp log_transient_fault do
    log(
      :error,
      Emoji.tired_face(),
      "Failed to start a dependency. This appears to be a transient fault. Try running again!"
    )
  end

  defp build_proxy_container(opts) do
    Container.new(opts.proxy_image)
    |> maybe_mount_proto_files(opts.protos)
    |> Container.with_environment("MIX_ENV", "prod")
    |> Container.with_environment("PROXY_APP_NAME", "proxy_#{generate()}")
    |> Container.with_environment("PROXY_CLUSTER_STRATEGY", "gossip")
    |> Container.with_environment("PROXY_DATABASE_TYPE", opts.database_type)
    |> Container.with_environment("PROXY_DATABASE_PORT", "#{opts.database_port}")
    |> Container.with_environment("PROXY_DATABASE_POOL_SIZE", "#{opts.database_pool}")
    |> Container.with_environment("PROXY_HTTP_PORT", "#{opts.proxy_bind_port}")
    |> Container.with_environment("PROXY_GRPC_PORT", "#{opts.proxy_bind_grpc_port}")
    |> Container.with_environment("PROXY_ACTOR_SYSTEM_NAME", "#{opts.actor_system}")
    |> Container.with_environment("SPAWN_USE_INTERNAL_NATS", "#{opts.enable_nats}")
    |> Container.with_environment("SPAWN_PROXY_LOGGER_LEVEL", opts.log_level)
    |> Container.with_environment("SPAWN_STATESTORE_KEY", opts.statestore_key)
    |> Container.with_environment("USER_FUNCTION_PORT", "#{opts.actor_host_port}")
    |> Container.with_environment("RELEASE_NAME", "#{opts.name}")
    |> Container.with_fixed_port(opts.proxy_bind_port)
    |> Container.with_exposed_port(opts.proxy_bind_grpc_port)
    |> maybe_use_host_network(opts)
    |> maybe_use_database_volume(opts)
    |> Container.with_label("spawn.actorsystem.name", opts.actor_system)
    |> Container.with_label("spawn.proxy.name", opts.name)
    |> Container.with_label("spawn.proxy.database.type", opts.database_type)
    |> Container.with_label("spawn.proxy.logger.level", opts.log_level)
  end

  defp maybe_use_host_network(container, _opts) do
    case :os.type() do
      {:win32, _} ->
        container

      {:unix, :darwin} ->
        container

      {:unix, _} ->
        container
        |> Container.with_network_mode("host")
    end
  end

  defp maybe_mount_proto_files(container, proto_files) do
    container
    |> Container.with_bind_mount(proto_files, "/app/priv/protos/", "rw")
  end

  defp maybe_use_database_volume(container, opts) do
    if opts.database_type == "native" do
      container
      |> Container.with_bind_volume("spawn_#{opts.actor_system}_data", "/data/")
    else
      container
    end
  end

  defp log_success({:win32, _}, container, opts), do: log_sucess_with_ports(container, opts)

  defp log_success({:unix, :darwin}, container, opts), do: log_sucess_with_ports(container, opts)

  defp log_success({:unix, _}, container, opts) do
    log(:info, Emoji.exclamation(), "Spawn Proxy using host network. Exposed ports: [
      Proxy HTTP: #{opts.proxy_bind_port},
      Proxy gRPC: #{opts.proxy_bind_grpc_port}
    ]")

    log(
      :info,
      Emoji.rocket(),
      "[#{get_time()}] Spawn Proxy started successfully. Container Id: #{container.container_id}"
    )
  end

  defp log_sucess_with_ports(container, opts) do
    log(:info, Emoji.exclamation(), "Spawn Proxy uses the following mapped ports: [
      Proxy HTTP: #{inspect(Container.mapped_port(container, opts.proxy_bind_port))}:#{opts.proxy_bind_port},
      Proxy gRPC: #{inspect(Container.mapped_port(container, opts.proxy_bind_grpc_port))}:#{opts.proxy_bind_grpc_port}
    ]")

    log(
      :info,
      Emoji.rocket(),
      "[#{get_time()}] Spawn Proxy started successfully. Container Id: #{container.container_id}"
    )
  end

  defp log_failure(error) do
    log(
      :error,
      Emoji.tired_face(),
      "Failure occurring during Spawn Proxy start phase. Details: #{inspect(error)}"
    )
  end

  defp get_time() do
    DateTime.utc_now() |> DateTime.to_string()
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
