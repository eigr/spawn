defmodule Operator.MixProject do
  use Mix.Project

  @app :operator

  def project do
    [
      app: @app,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Operator.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spawn, "~> 0.1", in_umbrella: true},
      {:metrics_endpoint, "~> 0.1", in_umbrella: true},
      {:bandit, "~> 0.5"},
      {:bonny, "~> 0.5"},
      {:bakeware, ">= 0.0.0", runtime: false}
    ]
  end
end
