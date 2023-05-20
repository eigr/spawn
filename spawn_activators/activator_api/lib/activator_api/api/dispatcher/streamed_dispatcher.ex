defmodule ActivatorAPI.Api.Dispatcher.StreamedDispatcher do
  @moduledoc """
  `StreamedDispatcher`
  """
  @behaviour ActivatorAPI.Api.Dispatcher

  require Logger

  @impl true
  def dispatch(_message, _stream, opts \\ []) do
  end
end
