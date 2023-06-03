defmodule Statestores.Manager.StateManager do
  @moduledoc """
  This module must be used by the proxy to interact with databases regardless of
  which provider is used.
  """
  import Statestores.Util, only: [load_snapshot_adapter: 0]

  def load(id), do: load_snapshot_adapter().get_by_key(id)

  def save(event), do: load_snapshot_adapter().save(event)
end
