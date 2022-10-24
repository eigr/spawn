defmodule SpawnSdk.MixProject do
  use Mix.Project

  @app :spawn_sdk
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      description: "Spawn Elixir SDK is the support library for the Spawn Actors System",
      source_url: "https://github.com/eigr/spawn/tree/main/spawn_sdk/spawn_sdk",
      homepage_url: "https://eigr.io/",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger
      ]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/eigr/spawn"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spawn, path: "../../"},
      {:faker, "~> 0.17", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
