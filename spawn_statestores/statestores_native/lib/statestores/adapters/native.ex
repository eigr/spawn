defmodule Statestores.Adapters.Native do
  @moduledoc """
  Implements the behavior defined in `Statestores.Adapters.Behaviour` for Native databases using Mnesia.
  """
  use Statestores.Adapters.Behaviour

  alias Statestores.Adapters.Native.Store
  alias Statestores.Schemas.Event

  def get_by_key(id) do
    :mnesia.transaction(fn ->
      :mnesia.index_read(Store, id, :id)
    end)
    |> case do
      {:atomic, []} -> nil
      {:atomic, [data]} -> Event.from_record_tuple(data)
      _ -> nil
    end
  end

  def save(event) do
    event_with_timestamps = %{
      event
      | updated_at: DateTime.utc_now(),
        inserted_at: DateTime.utc_now()
    }

    :mnesia.transaction(fn ->
      :mnesia.write(List.to_tuple([Store] ++ Event.to_record_list(event_with_timestamps)))
    end)
    |> case do
      {:atomic, :ok} ->
        {:ok, event}

      _ ->
        {:error, event}
    end
  end

  def default_port, do: "0"

  def get_children do
    [
      {Mnesiac.Supervisor, [Node.list(), [name: Statestores.MnesiacSupervisor]]}
    ]
  end
end
