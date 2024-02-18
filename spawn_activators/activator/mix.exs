defmodule Activators.MixProject do
  use Mix.Project

  @app :activator
  @version "0.0.0-local.dev"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "./_build",
      config_path: "../../config/config.exs",
      deps_path: "./deps",
      lockfile: "./mix.lock",
      elixir: "~> 1.14",
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
      {:spawn, path: "../../"},
      {:cloudevents, "~> 0.6.1"},
      {:hackney, "~> 1.9"}
    ]
  end
end
