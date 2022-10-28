import Config

config :opentelemetry,
  span_processor: :batch,
  traces_exporter: {:otel_exporter_stdout, []}

config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: "http://localhost:4318"
