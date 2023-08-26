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


  def return_and_maybe_hibernate(tuple) do
    queue_length = Process.info(self(), :message_queue_len)

    case queue_length do
      {:message_queue_len, 0} ->
        Tuple.append(tuple, :hibernate)

      _ ->
        tuple
    end
  end
end
