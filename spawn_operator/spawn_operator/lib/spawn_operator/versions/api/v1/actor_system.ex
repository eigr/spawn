defmodule SpawnOperator.Versions.Api.V1.ActorSystem do
  @moduledoc """
  ActorSystem CRD v1 version.
  """
  use Bonny.API.Version, hub: true

  import YamlElixir.Sigil

  @impl true
  def manifest() do
    struct!(
      defaults(),
      name: "v1",
      schema: ~y"""
      :openAPIV3Schema:
        :type: object
        :description: "Defines an Spawn ActorSystem to configure group of ActorHost applications."
        :required: ["spec"]
        :properties:
          :spec:
            type: object
            properties:
              cluster:
                type: object
                properties:
                  kind:
                    type: string
                    enum: ["erlang", "quic"]
                    default: "erlang"
                  cookie:
                    type: string
                  systemToSystem:
                    type: object
                    properties:
                      enabled:
                        type: boolean
                      natsClusterSecretRef:
                        type: string
                  tls:
                    type: object
                    properties:
                      secretName:
                        type: string
                      certManager:
                        type: object
                        properties:
                          enabled:
                            type: boolean
                          issuerName:
                            type: string
              statestore:
                type: object
                properties:
                  type:
                    type: string
                    enum: ["Native", "native", "MariaDB", "mariadb", "Postgres", "postgres"]
                  credentialsSecretRef:
                    type: string
                  pool:
                    type: object
                    properties:
                      size:
                        type: integer
      """a,
      additionalPrinterColumns: [
        %{
          name: "Cluster Kind",
          type: "string",
          description: "The kind of cluster used for the ActorSystem",
          jsonPath: ".spec.cluster.kind"
        },
        %{
          name: "Statestore",
          type: "string",
          description: "The type of state store used for the ActorSystem",
          jsonPath: ".spec.statestore.type"
        },
        %{
          name: "Pool Size",
          type: "string",
          description: "The pool size of the state store",
          jsonPath: ".spec.statestore.pool.size"
        }
      ]
    )
    |> add_observed_generation_status()
    |> add_conditions()
  end
end
