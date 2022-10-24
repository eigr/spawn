defmodule Spawn.MixProject do
  use Mix.Project

  @app :spawn

  def project do
    [
      app: @app,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :retry]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spawn_statestores, path: "./spawn_statestores/statestores", optional: true},
      {:cowlib, "~> 2.9", override: true},
      {:decimal, "~> 2.0", override: true},
      {:protobuf, "~> 0.10", override: true},
      {:finch, "~> 0.12"},
      {:retry, "~> 0.17"},
      {:tesla, "~> 1.4"},
      {:flow, "~> 1.2"},
      {:vapor, "~> 0.10"},
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.8"},
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.3"},
      {:faker, "~> 0.17", only: :test},
      {:mimic, "~> 1.7", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
