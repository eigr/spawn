defmodule Statestores.Manager.StateManager do
  @moduledoc """
  This module must be used by the proxy to interact with databases regardless of
  which provider is used.
  """
  import Statestores.Util, only: [load_snapshot_adapter: 0, load_projection_adapter: 0]

  def load(id), do: load_snapshot_adapter().get_by_key(id)

  def load(id, revision), do: load_snapshot_adapter().get_by_key_and_revision(id, revision)

  def save(event), do: load_snapshot_adapter().save(event)

  def projection_create_or_update_table(projection_type, table_name),
    do: load_projection_adapter().create_or_update_table(projection_type, table_name)

  def projection_upsert(projection_type, table_name, data),
    do: load_projection_adapter().upsert(projection_type, table_name, data)

  def projection_query(projection_type, query, params, opts),
    do: load_projection_adapter().query(projection_type, query, params, opts)
end
