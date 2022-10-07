defmodule Sidecar.MixProject do
  use Mix.Project

  @app :sidecar
  @version "0.1.0"

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
      elixirc_paths: elixirc_paths(Mix.env())
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
      {:actors, "~> 0.1", in_umbrella: true},
      {:spawn, "~> 0.1", in_umbrella: true},
      {:metrics_endpoint, "~> 0.1", in_umbrella: true},
      {:statestores, "~> 0.1", in_umbrella: true}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
