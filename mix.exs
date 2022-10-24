defmodule Spawn.MixProject do
  use Mix.Project

  @app :spawn

  def project do
    [
      app: @app,
      version: "0.1.0",
      description: "Spawn is the core lib for Spawn Actors System",
      source_url: "https://github.com/eigr/spawn",
      homepage_url: "https://eigr.io/",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => "https://github.com/eigr/spawn"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :retry]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowlib, "~> 2.9"},
      {:decimal, "~> 2.0"},
      {:protobuf, "~> 0.10"},
      {:finch, "~> 0.12"},
      {:retry, "~> 0.17"},
      {:tesla, "~> 1.4"},
      {:flow, "~> 1.2"},
      {:vapor, "~> 0.10"},
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.8"},
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.3"},
      {:faker, "~> 0.17", only: :test},
      {:mimic, "~> 1.7", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ] ++ deps_for_release()
  end

  @is_release System.get_env("RELEASE")

  defp deps_for_release do
    if @is_release do
      [
        {:spawn_statestores, "~> 0.1", optional: true}
      ]
    else
      [
        {:spawn_statestores,
         path: "./spawn_statestores/statestores", optional: Mix.env() != :test}
      ]
    end
  end

  defp elixirc_paths(:test),
    do: ["lib", "test/support", "spawn_statestores/statestores/test/support"]

  defp elixirc_paths(_), do: ["lib"]
end
