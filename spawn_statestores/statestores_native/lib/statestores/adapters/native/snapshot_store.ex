defmodule Statestores.Adapters.Native.SnapshotStore do
  @moduledoc """
  Snapshot store using Mnesiac.

  Orders of the fields matter here!!
  """

  use Mnesiac.Store
  require Logger

  import Record, only: [defrecord: 3]

  defrecord(
    :snapshots,
    __MODULE__,
    actor: nil,
    id: nil,
    system: nil,
    status: nil,
    revision: nil,
    tags: %{},
    data_type: nil,
    data: nil,
    updated_at: nil,
    inserted_at: nil
  )

  @type snapshot ::
          record(
            :snapshots,
            actor: String.t(),
            id: integer(),
            system: String.t(),
            status: String.t(),
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
      attributes: snapshots() |> snapshots() |> Keyword.keys(),
      index: [:id],
      type: :set,
      disc_copies: [node()]
    ]
  end

  @impl true
  def init_store do
    table_name = Keyword.get(store_options(), :record_name, __MODULE__)

    # By matching expected values if the table or store definitions is wrong it will error
    result =
      case :mnesia.create_table(table_name, store_options()) do
        {:aborted, {:already_exists, table}} -> {:aborted, {:already_exists, table}}
        {:atomic, :ok} -> {:atomic, :ok}
      end

    Logger.info("#{__MODULE__} Initialized with result #{inspect(result)}")

    result
  end

  @impl true
  def copy_store do
    table_name = Keyword.get(store_options(), :record_name, __MODULE__)

    result = :mnesia.add_table_copy(table_name, node(), :disc_copies)

    Logger.info("#{__MODULE__} Added table copy with result #{inspect(result)}")
  end

  @impl true
  def resolve_conflict(target_node) do
    table_name = Keyword.get(store_options(), :record_name, __MODULE__)

    Logger.warning(
      "Resolving conflict for table #{table_name} - with #{target_node} and #{node()}"
    )

    # assume the copy is the right version
    :mnesia.add_table_copy(table_name, node(), :disc_copies)

    :ok
  end
end
