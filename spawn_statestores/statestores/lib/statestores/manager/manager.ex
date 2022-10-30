defmodule Statestores.Manager.StateManager do
  import Statestores.Util, only: [load_adapter: 0]

  def load(key), do: load_adapter().get_by_key(key)

  def save(event), do: load_adapter().save(event)
end
