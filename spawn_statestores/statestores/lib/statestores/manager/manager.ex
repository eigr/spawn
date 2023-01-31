defmodule Statestores.Manager.StateManager do
  @moduledoc """
  This module must be used by the proxy to interact with databases regardless of
  which provider is used.
  """
  import Statestores.Util, only: [load_adapter: 0]

  def load(key), do: load_adapter().get_by_key(key)

  def save(event), do: load_adapter().save(event)
end
