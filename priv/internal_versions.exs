defmodule InternalVersions do
  # The order here is also the deploy order, its important to keep this way
  @versions [
    spawn_statestores: "0.5.0-alpha.10",
    spawn_statestores_mysql: "0.5.0-alpha.10",
    spawn_statestores_mssql: "0.5.0-alpha.10",
    spawn_statestores_postgres: "0.5.0-alpha.10",
    spawn_statestores_sqlite: "0.5.0-alpha.10",
    spawn_statestores_cockroachdb: "0.5.0-alpha.10",
    spawn: "0.5.0-alpha.10",
    spawn_sdk: "0.5.0-alpha.10",

    activator: "0.5.0-alpha.10",
    activator_grpc: "0.5.0-alpha.10",
    activator_http: "0.5.0-alpha.10",
    activator_kafka: "0.5.0-alpha.10",
    activator_pubsub: "0.5.0-alpha.10",
    activator_rabbitmq: "0.5.0-alpha.10",
    activator_sqs: "0.5.0-alpha.10",

    proxy: "0.5.0-alpha.10"
  ]

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

    if Enum.empty?(apps_to_release) do
      raise "You need to specify at least one app"
    end

    # Assert if hex user is correct
    {"eigr\n", 0} = System.cmd("mix", ["hex.user", "whoami"])

    Enum.each(apps_to_release, fn app ->
      {name, version} = app

      name = Atom.to_string(name)

      {dir, dir_back} = cond do
        String.starts_with?(name, "spawn_statestores") ->
          {"./spawn_statestores/#{String.replace(name, "spawn_", "")}", "../.."}

        String.starts_with?(name, "spawn_sdk") ->
          {"./spawn_sdk/#{name}", "../.."}

        true ->
          {"./", "."}
      end

      whole_command = "cd #{dir} \
      && mix deps.get \
      && HEX_API_KEY=#{key} mix hex.publish --yes #{replace?} #{dry_run?} \
      && cd #{dir_back}"

      IO.puts("- Releasing #{inspect(app)}")

      mix_file = File.read!("#{dir}/mix.exs")

      match_spawn_with_path = ~r(\{:spawn,\s*path:.*\})
      match_spawn_statestores_with_path = ~r(\{:spawn_statestores,\s*path:.*\})
      match_spawn_mysql_with_path = ~r(\{:spawn_statestores_mysql,\s*path:.*\})
      match_spawn_mssql_with_path = ~r(\{:spawn_statestores_mssql,\s*path:.*\})
      match_spawn_postgres_with_path = ~r(\{:spawn_statestores_postgres,\s*path:.*\})
      match_spawn_cockroachdb_with_path = ~r(\{:spawn_statestores_cockroachdb,\s*path:.*\})
      match_spawn_sqlite_with_path = ~r(\{:spawn_statestores_sqlite,\s*path:.*\})

      new_mix_exs = mix_file
        |> String.replace(match_spawn_with_path, dep_for("spawn"), global: false)
        |> String.replace(match_spawn_statestores_with_path, dep_for("spawn_statestores"), global: false)
        |> String.replace(match_spawn_mysql_with_path, dep_for("spawn_statestores_mysql", true), global: false)
        |> String.replace(match_spawn_mssql_with_path, dep_for("spawn_statestores_mssql", true), global: false)
        |> String.replace(match_spawn_postgres_with_path, dep_for("spawn_statestores_postgres", true), global: false)
        |> String.replace(match_spawn_cockroachdb_with_path, dep_for("spawn_statestores_cockroachdb", true), global: false)
        |> String.replace(match_spawn_sqlite_with_path, dep_for("spawn_statestores_sqlite", true), global: false)
        |> String.replace("0.0.0-local.dev", version)

      File.write!("#{dir}/mix.exs", new_mix_exs)

      System.shell(whole_command, into: IO.stream())

      IO.puts("-- Waiting some time to publish #{inspect(app)}...")
      Process.sleep(3_000)
    end)
  end

  defp get(app_name) do
    Keyword.fetch!(@versions, app_name)
  end

  defp get_version(app_name) do
    "~> #{get(String.to_existing_atom(app_name))}"
  end

  defp dep_for(app_name, optional? \\ false) do
    if optional? do
      "{:#{app_name}, \"#{get_version(app_name)}\", optional: true}"
    else
      "{:#{app_name}, \"#{get_version(app_name)}\"}"
    end
  end
end
