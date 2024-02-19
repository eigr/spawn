defmodule ActivatorRabbitMQ.MixProject do
  use Mix.Project

  @app :activator_rabbitmq
  @version "0.0.0-local.dev"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "../activator/_build",
      config_path: "../../config/config.exs",
      deps_path: "../activator/deps",
      lockfile: "../activator/mix.lock",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ActivatorRabbitMQ.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:activator, path: "../activator"},
      {:spawn, path: "../../"},
      {:bakeware, "~> 0.2"},
      {:bandit, "~> 1.1"},
      {:broadway_rabbitmq, "~> 0.7"},
      {:nimble_options, "~> 0.5.2", override: true}
    ]
  end

  defp releases do
    [
      activator_rabbitmq: [
        include_executables_for: [:unix],
        applications: [activator_rabbitmq: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end
end
