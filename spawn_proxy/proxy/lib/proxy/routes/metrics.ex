defmodule Proxy.Routes.Metrics do
  use Proxy.Routes.Base

  alias TelemetryMetricsPrometheus.Core, as: Prometheus

  @content_type "text/plain"

  get "/" do
    scrape = Prometheus.scrape(:spawm_metrics)
    send!(conn, 200, scrape, @content_type)
  end
end
