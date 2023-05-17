defmodule Statestores.Manager.StateManager do
  @moduledoc """
  This module must be used by the proxy to interact with databases regardless of
  which provider is used.
  """
  import Statestores.Util, only: [load_adapter: 0]

  def load(id), do: load_adapter().get_by_key(id)

  def save(event), do: load_adapter().save(event)
end
