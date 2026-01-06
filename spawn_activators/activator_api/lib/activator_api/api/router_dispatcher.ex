defmodule ActivatorAPI.Api.RouterDispatcher do
  @moduledoc """
  Dispatch requests to Actors Actions.
  """
  require Logger

  @behaviour ActivatorAPI.Api.Dispatcher

  alias ActivatorAPI.Api.Dispatcher.{
    StreamInDispatcher,
    StreamOutDispatcher,
    StreamedDispatcher,
    UnaryDispatcher
  }

  @impl true
  def dispatch(message, stream, opts \\ []) do
    Logger.debug(
      "Received message #{inspect(message)} from stream #{inspect(stream)} with options #{inspect(opts)}."
    )

    Keyword.get(opts, :request_type, "unary")
    |> case do
      "unary" ->
        UnaryDispatcher.dispatch(message, stream, opts)

      "stream_in" ->
        StreamInDispatcher.dispatch(message, stream, opts)

      "stream_out" ->
        StreamOutDispatcher.dispatch(message, stream, opts)

      "streamed" ->
        StreamedDispatcher.dispatch(message, stream, opts)

      _ ->
        raise ArgumentError, "Router not found for options #{inspect(opts)}!"
    end
  end
end
