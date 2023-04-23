defmodule Spawn.Cluster.Node.Server do
  @moduledoc """
  Node subscriber
  """
  use Gnat.Server

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  def request(%{topic: topic, body: body, reply_to: reply_to} = req) do
    Logger.debug("Received Actor Invocation via Nats on #{topic}")

    req
    |> Map.get(:headers)
    |> get_trace_context_if_exists()

    topic
    |> handle_request(body, reply_to)
  end

  def error(%{gnat: gnat, reply_to: reply_to}, _error) do
    # TODO handle errors
    # Gnat.pub(gnat, reply_to, "Something went wrong and I can't handle your request")
  end

  defp handle_request(topic, body, reply_to) do
    Tracer.with_span "Handle Actor Invoke", kind: :server do
      {:reply, nil}
    end
  end

  defp get_trace_context_if_exists(headers) do
    if Enum.any?(headers, fn {k, _v} -> k == "traceparent" end) do
      :otel_propagator_text_map.extract(headers)
    else
      OpenTelemetry.Ctx.clear()
    end
  end
end
