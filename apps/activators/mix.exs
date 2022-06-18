defmodule Activators.MixProject do
  use Mix.Project

  def project do
    [
      app: :activators,
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
      mod: {Activators.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:broadway_cloud_pub_sub, "~> 0.7"},
      {:broadway_kafka, "~> 0.3"},
      {:broadway_rabbitmq, "~> 0.7"},
      {:broadway_sqs, "~> 0.7"},
      # {:goth, "~> 1.0"},
      {:hackney, "~> 1.9"}
    ]
  end
end
