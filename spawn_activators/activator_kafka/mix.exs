defmodule ActivatorKafka.MixProject do
  use Mix.Project

  @app :activator_kafka
  @version "0.0.0-local.dev"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
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
      mod: {ActivatorKafka.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:activator, path: "../activator"},
      {:spawn, path: "../../"},
      {:broadway_kafka, "~> 0.3"},
      {:burrito, github: "burrito-elixir/burrito"},
      {:bandit, "~> 0.5"}
    ]
  end

  defp releases do
    [
      activator_kafka: [
        include_executables_for: [:unix],
        applications: [activator_kafka: :permanent],
        steps: [
          :assemble,
          &Burrito.wrap/1
        ],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64]
          ],
        ]
      ]
    ]
  end
end
