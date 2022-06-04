defmodule Spawn.MixProject do
  use Mix.Project

  def project do
    [
      app: :spawn,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :statestores],
      mod: {Spawn.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:statestores, "~> 0.1", in_umbrella: true},
      {:google_protos, "~> 0.2"},
      {:protobuf, "~> 0.9", override: true},
      {:grpc, "0.5.0-beta.1"},
      {:cowlib, "~> 2.9", override: true},
      {:bakeware, "~> 0.2"},
      {:decimal, "~> 1.9", override: true},
      {:flow, "~> 1.2"},
      {:vapor, "~> 0.10"},
      {:observer_cli, "~> 1.7"},
      {:plug_cowboy, "~> 2.5"},
      {:poison, "~> 5.0"},
      #{:prometheus, "~> 4.8"},
      #{:prometheus_plugs, "~> 1.1"},
      #{:telemetry, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.8"},
      {:phoenix_pubsub, "~> 2.1"}
    ]
  end

  defp releases() do
    [
      spawn: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end
end
