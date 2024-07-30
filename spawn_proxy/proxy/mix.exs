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
      elixir: "~> 1.15",
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
      {:spawn_statestores_mariadb,
       path: "../../spawn_statestores/statestores_mariadb", optional: false},
      {:spawn_statestores_postgres,
       path: "../../spawn_statestores/statestores_postgres", optional: false},
      {:spawn_statestores_native,
       path: "../../spawn_statestores/statestores_native", optional: false},
      {:bakeware, "~> 0.2"},
      {:bandit, "~> 1.5"},
      {:observer_cli, "~> 1.7"},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false}
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
