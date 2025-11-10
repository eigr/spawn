defmodule Spawn.MixProject do
  use Mix.Project

  Code.require_file("internal_versions.exs", "./priv")

  @app :spawn
  @version "0.0.0-local.dev"
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
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      aliases: [
        publish: &InternalVersions.publish/1,
        rewrite_versions: &InternalVersions.rewrite_versions/1
      ]
    ]
  end

  def application do
    [
      extra_applications: [
        :logger,
        :retry,
        :opentelemetry_exporter,
        :opentelemetry
      ]
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
      main: "Spawn",
      logo: "docs/images/sepp-elixir-254-400.png",
      source_url: @source_url,
      source_ref: "v#{@version}",
      source_url_pattern: "#{@source_url}/blob/v#{@version}/spawn/%{path}#L%{line}",
      formatter_opts: [gfm: true],
      extras: [
        "README.md",
        "guides/getting_started/quickstart.livemd"
      ]
    ]
  end

  defp deps do
    [
      {:decimal, "~> 2.0"},
      {:decorator, "~> 1.4"},
      {:iter, "~> 0.1.2"},
      {:nebulex, "~> 2.5"},
      {:shards, "~> 1.1"},
      {:telemetry, "~> 1.0"},
      {:castore, "~> 1.0"},
      {:protobuf, "~> 0.14"},
      {:protobuf_generate, "~> 0.1"},
      {:grpc, "~> 0.10"},
      {:grpc_reflection, "~> 0.2.0"},
      {:finch, "~> 0.18"},
      {:flame_k8s_backend, "~> 0.5"},
      {:retry, "~> 0.17"},
      {:flow, "~> 1.2"},
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.9"},
      {:highlander, "~> 0.2.1"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_pubsub_nats, "~> 0.2"},
      {:jason, "~> 1.3"},
      {:gnat, "~> 1.9"},
      {:jetstream, "~> 0.0.9"},
      {:k8s, "~> 2.2"},
      {:k8s_webhoox, "~> 0.2"},
      {:uuid, "~> 1.1"},
      {:broadway, "~> 1.1"},
      # temporary until bandit releases 1.5.4
      {:hpax, "~> 0.1.1"},
      # Add cowlib override for gun compatibility
      {:cowlib, "~> 2.15", override: true},
      # Metrics & Tracing deps
      {:telemetry_poller, "~> 1.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_metrics_prometheus_core, "~> 1.2.1"},
      {:opentelemetry_api, "~> 1.5"},
      {:opentelemetry, "~> 1.7"},
      {:opentelemetry_ecto, "~> 1.2"},
      {:opentelemetry_exporter, "~> 1.0"},
      # Statestores deps
      {:spawn_statestores_mariadb,
       path: "./spawn_statestores/statestores_mariadb", optional: false},
      {:spawn_statestores_postgres,
       path: "./spawn_statestores/statestores_postgres", optional: false},
      {:spawn_statestores_native,
       path: "./spawn_statestores/statestores_native", optional: false},
      {:pluggable, "~> 1.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test),
    do: ["lib", "test/support", "spawn_statestores/statestores/test/support"]

  defp elixirc_paths(_), do: ["lib"]
end
