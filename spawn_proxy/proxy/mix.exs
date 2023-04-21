defmodule Proxy.MixProject do
  use Mix.Project

  @app :proxy
  @version "0.0.0-local.dev"

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
      {:spawn, path: "../../"},
      {:bakeware, "~> 0.2"},
      {:bandit, "~> 0.7.7"},
      {:observer_cli, "~> 1.7"},
      {:spawn_statestores, path: "../../spawn_statestores/statestores"},
      {:spawn_statestores_mssql, path: "../../spawn_statestores/statestores_mssql"},
      {:spawn_statestores_mysql, path: "../../spawn_statestores/statestores_mysql"},
      {:spawn_statestores_postgres, path: "../../spawn_statestores/statestores_postgres"},
      {:spawn_statestores_sqlite, path: "../../spawn_statestores/statestores_sqlite"},
      {:spawn_statestores_cockroachdb, path: "../../spawn_statestores/statestores_cockroachdb"}
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
