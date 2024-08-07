defmodule SpawnCtl.MixProject do
  use Mix.Project

  @app :spawnctl
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
      mod: {SpawnCtl, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:burrito, "~> 1.1"},
      {:do_it, "~> 0.6"},
      {:earmark, "~> 1.4"},
      {:exmoji, "~> 0.3"},
      {:file_system, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:k8s, "~> 2.6"},
      {:req, "~> 0.4"},
      {:testcontainers, "~> 1.8.4"},
      # Non runtime deps
      {:credo, "~> 1.6", runtime: false}
    ]
  end

  def releases do
    [
      spawnctl: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64],
            linux_aarch64: [os: :linux, cpu: :aarch64],
            #linux_musl: [os: :linux, cpu: :x86_64, libc: :musl],
            macos: [os: :darwin, cpu: :x86_64],
            macos_m1: [os: :darwin, cpu: :aarch64],
            windows: [os: :windows, cpu: :x86_64]
          ],
          extra_steps: [
            fetch: [pre: [SpawnCtl.CustomBuildStep]],
            build: [post: [SpawnCtl.CustomBuildStep]]
          ],
          debug: Mix.env() != :prod
        ]
      ]
    ]
  end
end
