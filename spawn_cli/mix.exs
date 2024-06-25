defmodule SpawnCli.MixProject do
  use Mix.Project

  @app :spawn_cli
  @version "0.0.0-local.dev"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "_build",
      config_path: "config/config.exs",
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
      mod: {SpawnCli, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:burrito, "~> 1.0"},
      {:do_it, "~> 0.6"},
      {:exmoji, "~> 0.3"},
      {:jason, "~> 1.4"},
      {:k8s, "~> 2.6"},
      {:req, "~> 0.4"},
      # Non runtime deps
      {:credo, "~> 1.6", runtime: false}
    ]
  end

  def releases do
    [
      spawn_cli: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64],
            linux_musl: [os: :linux, cpu: :x86_64, libc: :musl]
            # macos: [os: :darwin, cpu: :x86_64],
            # windows: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end
end
