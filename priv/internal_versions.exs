defmodule InternalVersions do
  def elixir_version, do: "~> 1.14"

  # The order here is also the deploy order, its important to keep this way
  @versions [
    spawn_statestores: "0.5.0-alpha.1",
    spawn_statestores_mysql: "0.5.0-alpha.1",
    spawn_statestores_mssql: "0.5.0-alpha.1",
    spawn_statestores_postgres: "0.5.0-alpha.1",
    spawn_statestores_sqlite: "0.5.0-alpha.1",
    spawn_statestores_cockroachdb: "0.5.0-alpha.1",
    spawn: "0.5.0-alpha.1",
    spawn_sdk: "0.5.0-alpha.1",

    activator: "0.5.0-alpha.1",
    activator_grpc: "0.5.0-alpha.1",
    activator_http: "0.5.0-alpha.1",
    activator_kafka: "0.5.0-alpha.1",
    activator_pubsub: "0.5.0-alpha.1",
    activator_rabbitmq: "0.5.0-alpha.1",
    activator_sqs: "0.5.0-alpha.1",

    proxy: "0.5.0-alpha.1"
  ]

  def get(app_name) do
    Keyword.fetch!(@versions, app_name)
  end

  @is_release System.get_env("RELEASE")
  def internal_dep(app_name, path_opts \\ [], release_opts \\ []) do
    if @is_release do
      [{app_name, "~> #{get(app_name)}", release_opts}]
    else
      [{app_name, path_opts}]
    end
  end

  @doc """
    RUN before anything else:

    mix hex.user key generate

    Get this key and pass in params as the first argument

    Opts:
    --replace - replace current version even if its the same in hexpm
    --dry-run - dry run
    --all - publish all packages
    --apps=app1,app2 - specific apps to publish
  """
  def publish(opts) do
    key = List.first(opts)
    replace? = if "--replace" in opts, do: "--replace", else: ""
    dry_run? = if "--dry-run" in opts, do: "--dry-run", else: ""
    all? = "--all" in opts
    apps_to_publish = Enum.find(opts, "", & String.starts_with?(&1, "--apps")) |> String.replace("--apps=", "") |> String.split(",")
    |> IO.inspect

    IO.warn("***** Make sure you have generated the correct key for publishing, using: mix hex.user key generate")
    IO.puts("***** Currently using key: #{key}")
    IO.puts("- Starting release all with: #{replace?} #{dry_run?} for Versions:")

    apps_to_release = @versions
    |> Enum.filter(& elem(&1, 0) |> Atom.to_string() |> String.starts_with?("spawn"))

    apps_to_release = if all? do
      apps_to_release
    else
      Enum.filter(apps_to_release, & Atom.to_string(elem(&1, 0)) in apps_to_publish)
    end

    # print
    Enum.each(apps_to_release, & IO.puts("-- #{inspect(&1)}"))

    # Assert if hex user is correct
    {"eigr\n", 0} = System.cmd("mix", ["hex.user", "whoami"])

    Enum.each(apps_to_release, fn app ->
      {name, _version} = app

      name = Atom.to_string(name)

      {dir, dir_back} = cond do
        String.starts_with?(name, "spawn_statestores") ->
          {"./spawn_statestores/#{String.replace(name, "spawn_", "")}", "../.."}

        String.starts_with?(name, "spawn_sdk") ->
          {"./spawn_sdk/#{name}", "../.."}

        true ->
          {"./", "./"}
      end

      whole_command = "RELEASE=true cd #{dir}\
      && RELEASE=true mix deps.get\
      && HEX_API_KEY=#{key} RELEASE=true mix hex.publish --yes #{replace?} #{dry_run?}\
      && cd #{dir_back}"

      IO.puts("- Releasing #{inspect(app)}")

      System.shell(whole_command, into: IO.stream())

      IO.puts("-- Waiting some time to publish #{inspect(app)}...")
      Process.sleep(3_000)
    end)
  end
end
