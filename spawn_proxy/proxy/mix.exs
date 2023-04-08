defmodule Proxy.MixProject do
  use Mix.Project

  @app :proxy
  @version "0.5.3"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "../../_build",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools, :os_mon],
      mod: {Proxy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spawn, "~> 0.5"},
      {:bakeware, "~> 0.2"},
      {:bandit, "~> 0.5"},
      {:observer_cli, "~> 1.7"},
      {:spawn_statestores, "~> 0.5"},
      {:spawn_statestores_mssql, "~> 0.5", optional: true},
      {:spawn_statestores_mysql, "~> 0.5", optional: true},
      {:spawn_statestores_postgres, "~> 0.5", optional: true},
      {:spawn_statestores_sqlite, "~> 0.5", optional: true},
      {:spawn_statestores_cockroachdb, "~> 0.5", optional: true}
    ]
  end

  defp releases do
    [
      proxy: [
        include_executables_for: [:unix],
        applications: [proxy: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end
end
