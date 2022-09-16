defmodule ActivatorGRPC.MixProject do
  use Mix.Project

  @app :activator_grpc

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
      mod: {ActivatorGRPC.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:activator, "~> 0.1", in_umbrella: true},
      {:actors, "~> 0.1", in_umbrella: true},
      {:spawn, "~> 0.1", in_umbrella: true},
      {:metrics_endpoint, "~> 0.1", in_umbrella: true}
    ]
  end
end
