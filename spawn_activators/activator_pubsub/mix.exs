defmodule ActivatorPubSub.MixProject do
  use Mix.Project

  @app :activator_pubsub

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
      mod: {ActivatorPubSub.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:activator, path: "../activator"},
      {:spawn, path: "../../"},
      {:bakeware, "~> 0.2"},
      {:bandit, "~> 0.5"}
      # {:broadway_cloud_pub_sub, "~> 0.7"},
      # {:goth, "~> 1.0"}
    ]
  end

  defp releases do
    [
      activator_pubsub: [
        include_executables_for: [:unix],
        applications: [activator_pubsub: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end
end
