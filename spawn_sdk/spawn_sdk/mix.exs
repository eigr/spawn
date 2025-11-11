defmodule SpawnSdk.MixProject do
  use Mix.Project

  @app :spawn_sdk
  @version "0.0.0-local.dev"
  @source_url "https://github.com/eigr/spawn/tree/main/spawn_sdk/spawn_sdk"

  def project do
    [
      app: @app,
      version: @version,
      description: "Spawn Elixir SDK is the support library for the Spawn Actors System",
      name: "Spawn Elixir SDK",
      source_url: @source_url,
      homepage_url: "https://eigr.io/",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
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
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      licenses: ["Apache-2.0"],
      links: %{GitHub: @source_url}
    ]
  end

  defp docs do
    [
      main: "SpawnSdk.Actor",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatter_opts: [gfm: true],
      extras: [
        "guides/basic/quickstart.md",
        "guides/basic/actor_types.md",
        "guides/basic/actor_configuration.md",
        "guides/basic/client_api.md",
        "guides/basic/supervision.md",
        "guides/advanced/side_effects.md",
        "guides/advanced/forwards_and_pipes.md",
        "guides/advanced/broadcast.md"
      ],
      groups_for_extras: [
        "Getting Started": [
          "guides/basic/quickstart.md"
        ],
        "Basic Concepts": [
          "guides/basic/actor_types.md",
          "guides/basic/actor_configuration.md",
          "guides/basic/client_api.md",
          "guides/basic/supervision.md"
        ],
        "Advanced Features": [
          "guides/advanced/side_effects.md",
          "guides/advanced/forwards_and_pipes.md",
          "guides/advanced/broadcast.md"
        ]
      ],
      groups_for_modules: [
        "Actors": [
          SpawnSdk.Actor,
          SpawnSdk.System.Supervisor,
          SpawnSdk.Context,
          SpawnSdk.Value
        ],
        Workflows: [
          SpawnSdk.Flow.Broadcast,
          SpawnSdk.Flow.Forward,
          SpawnSdk.Flow.Pipe,
          SpawnSdk.Flow.SideEffect
        ],
        Deprecated: [
          SpawnSdk
        ],
        Miscellaneous: [
          SpawnSdk.Defact,
          SpawnSdk.System,
          SpawnSdk.System.SpawnSystem,
          SpawnSdk.Channel.Subscriber
        ]
      ]
    ]
  end

  defp deps do
    [
      {:spawn, path: "../.."},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
