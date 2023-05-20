defmodule ActivatorAPI.Api.Dispatcher.StreamOutDispatcher do
  @moduledoc """
  `StreamOutDispatcher`
  """
  @behaviour ActivatorAPI.Api.Dispatcher

  require Logger

  @impl true
  def dispatch(_message, _stream, opts \\ []) do
  end
end
