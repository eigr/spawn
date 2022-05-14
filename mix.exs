defmodule Spawn.MixProject do
  use Mix.Project

  def project do
    [
      app: :spawn,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Spawn.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bakeware, "~> 0.2"},
      {:vapor, "~> 0.10"},
      {:observer_cli, "~> 1.7"},
      {:plug_cowboy, "~> 2.5"},
      {:poison, "~> 5.0"},
      {:prometheus, "~> 4.8"},
      {:prometheus_plugs, "~> 1.1"},
      {:telemetry, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.8"},
      {:google_protos, "~> 0.2.0"},
      {:protobuf, "~> 0.9.0", override: true},
      {:grpc, github: "elixir-grpc/grpc", override: true}
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
