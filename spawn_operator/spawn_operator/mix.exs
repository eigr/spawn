defmodule Operator.MixProject do
  use Mix.Project

  @app :spawn_operator
  @version "0.0.0-local.dev"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "../../_build",
      config_path: "config/config.exs",
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
      extra_applications: [:logger],
      mod: {SpawnOperator.Application, [env: Mix.env()]}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 0.5"},
      {:bakeware, ">= 0.0.0", runtime: false},
      {:bonny, "~> 1.0.0-rc.1"},
      {:spawn, path: "../../"}
    ]
  end

  defp releases do
    [
      spawn_operator: [
        include_executables_for: [:unix],
        applications: [spawn_operator: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end
end
