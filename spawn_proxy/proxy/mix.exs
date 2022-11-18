defmodule Proxy.MixProject do
  use Mix.Project

  @app :proxy
  @version "0.0.0-local.dev"

  def project do
    [
      app: @app,
      version: @version,
      build_path: "../../_build",
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
      extra_applications: [:logger, :runtime_tools, :os_mon],
      mod: {Proxy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spawn, path: "../../"},
      {:burrito, github: "burrito-elixir/burrito"},
      {:bandit, "~> 0.5"},
      {:observer_cli, "~> 1.7"}
    ]
  end

  defp releases do
    [
      proxy: [
        include_executables_for: [:unix],
        applications: [proxy: :permanent],
        steps: [
          :assemble,
          &Burrito.wrap/1
        ],
        burrito: [
          targets: [
            #linux: [os: :linux, cpu: :x86_64],
            linux: [os: :linux, cpu: :x86_64, libc: :musl],
          ],
        ]
      ]
    ]
  end
end
