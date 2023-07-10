defmodule Spawn.Cluster.Node.Server do
  @moduledoc """
  Node subscriber
  """
  use Gnat.Server

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Eigr.Functions.Protocol.{InvocationRequest, ActorInvocationResponse}

  def request(%{topic: topic, body: body, reply_to: reply_to} = req)
      when is_binary(body) do
    Logger.info("Received Actor Invocation via Nats on #{topic}")
    headers = Map.get(req, :headers, [])

    handle_request(topic, body, reply_to, headers)
  end

  def request(%{topic: topic, body: _, reply_to: _reply_to} = _req) do
    Logger.warning("Received Invalid Actor Invocation via Nats on #{topic}")
    {:reply, {:error, :bad_request}}
  end

  def error(%{gnat: gnat, reply_to: reply_to}, error) do
    Logger.error(
      "Error on #{inspect(__MODULE__)} during handle incoming message. Error  #{inspect(error)}"
    )

    Gnat.pub(gnat, reply_to, error)
  end

  defp handle_request(_topic, body, reply_to, headers) do
    opts = headers_to_opts(headers)

    Tracer.with_span opts[:span_ctx], "Handle Actor Invoke", kind: :server do
      request = InvocationRequest.decode(body)

      Actors.invoke_with_span(request, opts)
      |> handle_reply(reply_to)
    end
  end

  defp headers_to_opts(headers) do
    ctx =
      if Enum.any?(headers, fn {k, _v} -> k == "traceparent" end) do
        :otel_propagator_text_map.extract(headers)
      else
        OpenTelemetry.Ctx.new()
      end

    Keyword.put([], :span_ctx, ctx)
  end

  defp handle_reply(_response, nil), do: :ok

  defp handle_reply(response, _reply_to) do
    case response do
      {:ok, :async} ->
        {:reply, "async"}

      {:ok, response} ->
        {:reply, ActorInvocationResponse.encode(response)}

      {:error, error} ->
        {:reply, error}
    end
  end
end
