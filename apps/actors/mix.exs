defmodule Actors.MixProject do
  use Mix.Project

  @app :actors

  def project do
    [
      app: @app,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cluster, "~> 0.1", in_umbrella: true},
      {:protos, "~> 0.1", in_umbrella: true},
      {:statestores, "~> 0.1", in_umbrella: true},
      {:cowlib, "~> 2.9", override: true},
      {:decimal, "~> 2.0", override: true},
      {:finch, "~> 0.12"},
      {:tesla, "~> 1.4"},
      {:flow, "~> 1.2"},
      {:vapor, "~> 0.10"},
      {:jason, "~> 1.2"},
      {:faker, "~> 0.17", only: :test},
      {:mimic, "~> 1.7", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
