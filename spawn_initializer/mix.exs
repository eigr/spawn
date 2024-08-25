defmodule SpawnInitializer.MixProject do
  use Mix.Project

  @app :spawn_initializer
  @version "1.4.3"
  @site "https://eigr.io/"
  @source_url "https://github.com/eigr/spawn"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SpawnInitializer, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bakeware, ">= 0.0.0", runtime: false},
      {:k8s, "~> 2.2"},
      {:k8s_webhoox, "~> 0.2"}
    ]
  end

  defp releases do
    [
      spawn_initializer: [
        include_executables_for: [:unix],
        applications: [spawn_initializer: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end

  defp elixirc_paths(:test),
    do: ["lib", "test/support"]

  defp elixirc_paths(_), do: ["lib"]
end
