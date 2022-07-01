defmodule Statestores.Adapters.Behaviour do
  alias Statestores.Schemas.Event

  @type actor :: String.t()

  @type event :: Event.t()

  @callback get_by_key(actor()) :: event()

  @callback save(event()) :: {:error, any} | {:ok, event()}
end
