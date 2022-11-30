defmodule Spawn.Utils.Common do
  @moduledoc false
  def to_existing_atom_or_new(string) do
    String.to_existing_atom(string)
  rescue
    _e ->
      String.to_atom(string)
  end
end
