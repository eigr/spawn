defmodule Spawn.Cluster.Node.Server do
  @moduledoc """
  Node subscriber
  """
  use Gnat.Server

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Eigr.Functions.Protocol.{InvocationRequest, ActorInvocationResponse}

  def request(%{topic: topic, body: body, reply_to: reply_to} = req) when is_binary(body) do
    Logger.debug("Received Actor Invocation via Nats on #{topic}")

    # req
    # |> Map.get(:headers)
    # |> get_trace_context_if_exists()

    topic
    |> handle_request(body, reply_to)
  end

  def request(%{topic: topic, body: _, reply_to: reply_to} = req) do
    Logger.debug("Received Invalid Actor Invocation via Nats on #{topic}")
    # TODO: Better response
    {:reply, "Bad Request"}
  end

  def error(%{gnat: gnat, reply_to: reply_to}, error) do
    Logger.error(
      "Error on #{inspect(__MODULE__)} during handle incoming message. Error  #{inspect(error)}"
    )

    Gnat.pub(gnat, reply_to, error)
  end

  defp handle_request(topic, body, _reply_to) do
    Tracer.with_span "Handle Actor Invoke", kind: :server do
      request = InvocationRequest.decode(body)

      case Actors.invoke_with_span(request, []) do
        {:ok, :async} ->
          {:reply, :async}

        {:ok, response} ->
          {:reply, Eigr.Functions.Protocol.ActorInvocationResponse.encode(response)}

        {:error, error} ->
          {:reply, error}
      end
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
