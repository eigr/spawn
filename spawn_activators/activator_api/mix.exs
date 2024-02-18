defmodule ActivatorAPI.MixProject do
  use Mix.Project

  @app :activator_api
  @version "0.0.0-local.dev"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "../activator/_build",
      config_path: "../../config/config.exs",
      deps_path: "../activator/deps",
      lockfile: "../activator/mix.lock",
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
      mod: {ActivatorAPI.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:activator, path: "../activator"},
      {:grpc, "~> 0.5"},
      {:gun, "~> 2.0", override: true},
      {:cowlib, "~> 2.11", override: true}
    ]
  end

  defp releases do
    [
      activator_api: [
        include_executables_for: [:unix],
        applications: [activator_api: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end
end
