defmodule Statestores.Manager.ProjectionStateManager do
  @moduledoc """
  This module must be used by the proxy to interact with projection databases regardless of which provider is used.
  """
  import Statestores.Util, only: [load_projection_adapter: 0]

  def create_table(table_name), do: load_projection_adapter().create_table(table_name)
end
