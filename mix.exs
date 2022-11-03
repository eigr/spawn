defmodule Spawn.MixProject do
  use Mix.Project

  Code.require_file("internal_versions.exs", "./priv/")

  @app :spawn
  @version InternalVersions.get(@app)
  @site "https://eigr.io/"
  @source_url "https://github.com/eigr/spawn"

  def project do
    [
      app: @app,
      version: @version,
      description: "Spawn is the core lib for Spawn Actors System",
      source_url: @source_url,
      homepage_url: @site,
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: InternalVersions.elixir_version(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      aliases: [publish: &InternalVersions.publish/1]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :retry]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "priv", "README.md", "LICENSE"],
      licenses: ["Apache-2.0"],
      links: %{GitHub: @source_url, Site: @site}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatter_opts: [gfm: true],
      extras: [
        "README.md"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowlib, "~> 2.9"},
      {:decimal, "~> 2.0"},
      {:protobuf, "~> 0.10"},
      {:finch, "~> 0.12"},
      {:retry, "~> 0.17"},
      {:tesla, "~> 1.4"},
      {:flow, "~> 1.2"},
      {:vapor, "~> 0.10"},
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.8"},
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.3"},
      {:opentelemetry_api, "~> 1.0"},
      {:opentelemetry, "~> 1.0"},
      {:opentelemetry_exporter, "~> 1.0"},
      {:faker, "~> 0.17", only: :test},
      {:mimic, "~> 1.7", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:pluggable, "~> 1.0.1", only: :dev, runtime: false}
    ] ++
      InternalVersions.internal_dep(
        :spawn_statestores_mssql,
        [path: "./spawn_statestores/statestores_mssql", optional: false],
        optional: true
      ) ++
      InternalVersions.internal_dep(
        :spawn_statestores_mysql,
        [path: "./spawn_statestores/statestores_mysql", optional: false],
        optional: true
      ) ++
      InternalVersions.internal_dep(
        :spawn_statestores_postgres,
        [path: "./spawn_statestores/statestores_postgres", optional: false],
        optional: true
      ) ++
      InternalVersions.internal_dep(
        :spawn_statestores_sqlite,
        [path: "./spawn_statestores/statestores_sqlite", optional: false],
        optional: true
      ) ++
      InternalVersions.internal_dep(
        :spawn_statestores_cockroachdb,
        [path: "./spawn_statestores/statestores_cockroachdb", optional: false],
        optional: true
      )
  end

  defp elixirc_paths(:test),
    do: ["lib", "test/support", "spawn_statestores/statestores/test/support"]

  defp elixirc_paths(_), do: ["lib"]
end
