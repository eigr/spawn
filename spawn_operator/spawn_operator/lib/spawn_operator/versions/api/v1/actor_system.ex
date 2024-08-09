defmodule SpawnOperator.Versions.Api.V1.ActorSystem do
  use Bonny.API.Version

  @impl true
  def manifest() do
    defaults()
    |> struct!(
      name: "v1",
      storage: true
    )
    |> add_observed_generation_status()
  end
end

defmodule SpawnOperator.Versions.Api.V1.ActorSystem do
  @moduledoc """
  ActorSystem CRD v1 version.
  """
  use Bonny.API.Version,
    hub: true

  import YamlElixir.Sigil

  @impl true
  def manifest() do
    struct!(
      defaults(),
      name: "v1",
      schema: ~y"""
      :openAPIV3Schema:
        :type: object
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
                    enum: ["Postgres"]
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
          name: "State Store Type",
          type: "string",
          description: "The type of state store used for the ActorSystem",
          jsonPath: ".spec.statestore.type"
        }
      ]
    )
    |> add_observed_generation_status()
    |> add_conditions()
  end
end
