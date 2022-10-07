defmodule Activators.MixProject do
  use Mix.Project

  @app :activator

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
      {:spawn, path: "../../apps/spawn"},
      {:actors, path: "../../apps/actors"},
      {:cloudevents, "~> 0.6.1"},
      {:hackney, "~> 1.9"}
    ]
  end
end
