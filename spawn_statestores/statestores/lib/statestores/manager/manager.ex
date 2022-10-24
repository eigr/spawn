defmodule Statestores.Manager.StateManager do
  import Statestores.Util, only: [load_repo: 0]

  def load(key), do: load_repo().get_by_key(key)

  def save(event), do: load_repo().save(event)
end
