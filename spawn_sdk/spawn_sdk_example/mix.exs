defmodule SpawnSdkExample.MixProject do
  use Mix.Project

  @app :spawn_sdk_example
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "_build",
      config_path: "../../config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
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
      mod: {SpawnSdkExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spawn_sdk, path: "../spawn_sdk"},
      # TODO: Removing :spawn_statestores dependency
      # shouldn't affect functionality, statestores should be optional
      # remove spawn_statestores from _build and test running sdk locally to see its effect
      {:ecto_sql, "~> 3.12"},
      {:spawn_statestores, path: "../../spawn_statestores/statestores"},
      {:bakeware, "~> 0.2"},
      {:benchee, "~> 1.0", only: :dev},
      {:benchee_html, "~> 1.0", only: :dev}
    ]
  end

  defp releases do
    [
      spawn_sdk_example: [
        include_executables_for: [:unix],
        applications: [spawn_sdk_example: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end
end
