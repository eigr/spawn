defmodule SpawnOperator.Versions.Api.V1.ActorHost do
  @moduledoc """
  ActorHost CRD v1 version.
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
        :description: |
          Defines an ActorHost application. Example:


          ---
          apiVersion: spawn-eigr.io/v1
          kind: ActorHost
          metadata:
            name: my-java-app
          spec:
            host:
              image: ghcr.io/eigr/spawn-springboot-examples:latest
              sdk: java
              ports:
              - containerPort: 80

        :required: ["spec"]
        :properties:
          :spec:
            type: object
            properties:
              autoscaler:
                type: object
                properties:
                  min:
                    type: integer
                  max:
                    type: integer
                  averageCpuUtilizationPercentage:
                    type: integer
                  averageMemoryUtilizationValue:
                    type: integer
              affinity:
                type: object
              replicas:
                type: integer
              volumes:
                type: array
                items:
                  type: object
                  properties:
                    name:
                      type: string
                    configMap:
                      type: object
                      properties:
                        name:
                          type: string
                        items:
                          type: array
                          items:
                            type: object
                            properties:
                              key:
                                type: string
                              path:
                                type: string
                    emptyDir:
                      type: object
                      properties:
                        medium:
                          type: string
                          enum: ["", "Memory"]
                        sizeLimit:
                          type: string
                    persistentVolumeClaim:
                      type: object
                      properties:
                        claimName:
                          type: string
                        readOnly:
                          type: boolean
                    secret:
                      type: object
                      properties:
                        secretName:
                          type: string
                        items:
                          type: array
                          items:
                            type: object
                            properties:
                              key:
                                type: string
                              path:
                                type: string
                    hostPath:
                      type: object
                      properties:
                        path:
                          type: string
                        type:
                          type: string
                          enum: ["", "DirectoryOrCreate", "Directory", "FileOrCreate", "File", "Socket", "CharDevice", "BlockDevice"]
                    projected:
                      type: object
                      properties:
                        sources:
                          type: array
                          items:
                            type: object
                            properties:
                              configMap:
                                type: object
                                properties:
                                  name:
                                    type: string
                                  items:
                                    type: array
                                    items:
                                      type: object
                                      properties:
                                        key:
                                          type: string
                                        path:
                                          type: string
                              secret:
                                type: object
                                properties:
                                  name:
                                    type: string
                                  items:
                                    type: array
                                    items:
                                      type: object
                                      properties:
                                        key:
                                          type: string
                                        path:
                                          type: string
                    downwardAPI:
                      type: object
                      properties:
                        items:
                          type: array
                          items:
                            type: object
                            properties:
                              path:
                                type: string
                              fieldRef:
                                type: object
                                properties:
                                  fieldPath:
                                    type: string
                              resourceFieldRef:
                                type: object
                                properties:
                                  containerName:
                                    type: string
                                  resource:
                                    type: string
                                  divisor:
                                    type: string
              topology:
                type: object
                properties:
                  nodeSelector:
                    type: object
                    additionalProperties:
                      type: string
                  tolerations:
                    type: array
                    items:
                      type: object
                      properties:
                        key:
                          type: string
                        operator:
                          type: string
                        effect:
                          type: string
              host:
                type: object
                required:
                  - image
                properties:
                  image:
                    type: string
                  imagePullSecrets:
                    type: array
                    items:
                      type: object
                      properties:
                        name:
                          type: string
                  volumeMounts:
                    type: array
                    items:
                      type: object
                      properties:
                        name:
                          type: string
                        mountPath:
                          type: string
                  embedded:
                    type: boolean
                  sdk:
                    type: string
                    enum: ["dart", "elixir", "go", "java", "python", "rust", "springboot", "nodejs"]
                  ports:
                    type: array
                    items:
                      type: object
                      properties:
                        name:
                          type: string
                        containerPort:
                          type: integer
                  env:
                    type: array
                    items:
                      type: object
                      properties:
                        name:
                          type: string
                        value:
                          type: string
                        valueFrom:
                          type: object
                          properties:
                            fieldRef:
                              type: object
                              properties:
                                fieldPath:
                                  type: string
                  taskActors:
                    type: array
                    items:
                      type: object
                      properties:
                        actorName:
                          type: string
                        workerPool:
                          type: object
                          properties:
                            min:
                              type: integer
                            max:
                              type: integer
                            maxConcurrency:
                              type: integer
                            bootTimeout:
                              type: integer
                            callTimeout:
                              type: integer
                            oneOff:
                              type: string
                              enum: ["true", "false"]
                            idleShutdownAfter:
                              type: integer
                        topology:
                          type: object
                          properties:
                            nodeSelector:
                              type: object
                              additionalProperties:
                                type: string
                            tolerations:
                              type: array
                              items:
                                type: object
                                properties:
                                  key:
                                    type: string
                                  operator:
                                    type: string
                                  effect:
                                    type: string
      """a,
      additionalPrinterColumns: [
        %{
          name: "SDK",
          type: "string",
          description: "SDK used by the ActorHost",
          jsonPath: ".spec.host.sdk"
        },
        %{
          name: "Embedded",
          type: "string",
          description: "Embedded Proxy used by the ActorHost",
          jsonPath: ".spec.host.embedded"
        },
        %{
          name: "Image",
          type: "string",
          description: "Docker image used for the ActorHost",
          jsonPath: ".spec.host.image"
        },
        %{
          name: "Min Replicas",
          type: "integer",
          description: "Minimum number of replicas for the ActorHost",
          jsonPath: ".spec.autoscaler.min"
        },
        %{
          name: "Max Replicas",
          type: "integer",
          description: "Maximum number of replicas for the ActorHost",
          jsonPath: ".spec.autoscaler.max"
        }
      ]
    )
    |> add_observed_generation_status()
    |> add_conditions()
  end
end
