defmodule ActivatorHTTP.MixProject do
  use Mix.Project

  @app :activator_http

  def project do
    [
      app: @app,
      version: "0.1.0",
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
      mod: {ActivatorHTTP.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:activator, path: "../activator"},
      {:actors, path: "../../apps/actors"},
      {:spawn, path: "../../apps/spawn"},
      {:metrics_endpoint, path: "../../apps/metrics_endpoint"},
      {:bakeware, "~> 0.2"},
      {:bandit, "~> 0.5"}
    ]
  end

  defp releases do
    [
      activator_http: [
        include_executables_for: [:unix],
        applications: [activator_http: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end
end
