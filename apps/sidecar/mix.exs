defmodule Sidecar.MixProject do
  use Mix.Project

  def project do
    [
      app: :sidecar,
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
      mod: {Sidecar.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 0.5"},
      {:prometheus, "~> 4.8"},
      {:prometheus_plugs, "~> 1.1"}
    ]
  end
end
