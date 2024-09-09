import Config

if config_env() == :prod do
  config :logger,
    level: String.to_atom(System.get_env("SPAWN_PROXY_LOGGER_LEVEL", "info"))
end

# For OTLP set the following variables:

#OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://localhost:55681
#OTEL_EXPORTER_OTLP_TRACES_PROTOCOL=grpc
#OTEL_EXPORTER_OTLP_TRACES_COMPRESSION=gzip
