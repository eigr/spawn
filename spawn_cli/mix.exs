defmodule SpawnCli.MixProject do
  use Mix.Project

  @app :spawn_cli
  @version "0.0.0-local.dev"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "../../_build",
      config_path: "config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
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
      {:bonny, "~> 1.1"},
      {:castore, "~> 1.0"},
      {:do_it, "~> 0.4"},
      {:burrito, github: "burrito-elixir/burrito"}
    ]
  end

  # defp releases do
  #   [
  #     spawn_cli: [
  #       include_executables_for: [:unix],
  #       applications: [spawn_cli: :permanent],
  #       steps: [
  #         :assemble,
  #         &Bakeware.assemble/1
  #       ],
  #       bakeware: [compression_level: 19]
  #     ]
  #   ]
  # end

  def releases do
    [
      spawn_cli: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64],
            linux_musl: [os: :linux, cpu: :x86_64, libc: :musl],
            macos: [os: :darwin, cpu: :x86_64],
            windows: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end
end
