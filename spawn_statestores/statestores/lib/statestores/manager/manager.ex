defmodule Statestores.Manager.StateManager do
  @moduledoc """
  This module must be used by the proxy to interact with databases regardless of
  which provider is used.
  """
  import Statestores.Util, only: [load_snapshot_adapter: 0]

  def load(id), do: load_snapshot_adapter().get_by_key(id)

  def load(id, revision), do: load_snapshot_adapter().get_by_key_and_revision(id, revision)

  def load_all(id), do: load_snapshot_adapter().get_all_snapshots_by_key(id)

  def load_by_interval(id, time_start, time_end),
    do: load_snapshot_adapter().get_snapshots_by_interval(id, time_start, time_end)

  def save(event), do: load_snapshot_adapter().save(event)
end
