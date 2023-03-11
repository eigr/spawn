defmodule ActivatorGrpc.Api.Dispatcher do
  @moduledoc """
  Dispatch requests to Actors.
  """
  require Logger

  def dispatch(payload) do
    Logger.debug("Received request with Payload #{inspect(payload)}")
  end
end
