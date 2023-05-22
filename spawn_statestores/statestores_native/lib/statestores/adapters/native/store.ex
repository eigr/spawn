defmodule Statestores.Adapters.Native.Store do
  @moduledoc """
  Provides the structure of events records.

  Orders of the fields matter here!!
  """
  use Mnesiac.Store
  require Logger

  import Record, only: [defrecord: 3]

  defrecord(
    :events,
    __MODULE__,
    actor: nil,
    id: nil,
    system: nil,
    revision: nil,
    tags: %{},
    data_type: nil,
    data: nil,
    updated_at: nil,
    inserted_at: nil
  )

  @type event ::
          record(
            :events,
            actor: String.t(),
            id: integer(),
            system: String.t(),
            revision: integer(),
            tags: map(),
            data_type: String.t(),
            data: binary(),
            updated_at: DateTime.t(),
            inserted_at: DateTime.t()
          )

  @impl true
  def store_options do
    [
      record_name: __MODULE__,
      attributes: events() |> events() |> Keyword.keys(),
      index: [:id],
      type: :set,
      disc_only_copies: [node()]
    ]
  end

  @impl true
  def init_store do
    options = store_options()

    :mnesia.create_table(__MODULE__, options)
  end

  @impl true
  def copy_store do
    for type <- [:ram_copies, :disc_copies, :disc_only_copies] do
      value = Keyword.get(store_options(), type, [])

      if Enum.member?(value, node()) do
        :mnesia.add_table_copy(
          __MODULE__,
          node(),
          type
        )
      end
    end
  end

  @impl true
  def resolve_conflict(_cluster_node) do
    table_name = __MODULE__

    Logger.info(fn ->
      "[mnesiac:#{node()}] #{inspect(table_name)}: data found on both sides, copy aborted."
    end)

    :ok
  end
end
