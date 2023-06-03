defmodule Spawn.Utils.Common do
  @moduledoc false

  alias Eigr.Functions.Protocol.Actors.ActorId

  def to_existing_atom_or_new(string) do
    String.to_existing_atom(string)
  rescue
    _e ->
      String.to_atom(string)
  end

  @spec generate_key(ActorId.t()) :: integer()
  def generate_key(id), do: :erlang.phash2({id.name, id.system})
end
