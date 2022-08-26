defmodule Spawn.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end

  defp releases() do
    [
      operator: [
        include_executables_for: [:unix],
        applications: [operator: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ],
      proxy: [
        include_executables_for: [:unix],
        applications: [proxy: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ],
      activator_grpc: [
        include_executables_for: [:unix],
        applications: [activator_grpc: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ],
      activator_http: [
        include_executables_for: [:unix],
        applications: [activator_http: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ],
      activator_kafka: [
        include_executables_for: [:unix],
        applications: [activator_kafka: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ],
      activator_pubsub: [
        include_executables_for: [:unix],
        applications: [activator_pubsub: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ],
      activator_rabbitmq: [
        include_executables_for: [:unix],
        applications: [activator_rabbitmq: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ],
      activator_sqs: [
        include_executables_for: [:unix],
        applications: [activator_sqs: :permanent],
        steps: [
          :assemble,
          &Bakeware.assemble/1
        ],
        bakeware: [compression_level: 19]
      ]
    ]
  end
end
