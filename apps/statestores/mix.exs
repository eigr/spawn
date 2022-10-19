defmodule Statestores.MixProject do
  use Mix.Project

  @app :statestores

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
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
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
      {:spawn, "~> 0.1", in_umbrella: true, only: :test},
      {:cloak_ecto, "~> 1.2"},
      {:ecto3_mnesia, "~> 0.2.0"},
      {:ecto_sql, "~> 3.8"},
      {:ecto_sqlite3, "~> 0.8.2"},
      {:myxql, "~> 0.6"},
      {:postgrex, "~> 0.16"},
      {:tds, "~> 2.3"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
