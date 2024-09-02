defmodule StatestoreController.CDC.Postgres.Tx.Operation do
  @moduledoc """
  `Describes` a change (INSERT, UPDATE, DELETE) within a transaction.
  """

  import Postgrex.PgOutput.Messages
  alias Postgrex.PgOutput.Type, as: PgType

  @type t :: %__MODULE__{}
  defstruct [
    :type,
    :schema,
    :namespace,
    :table,
    :record,
    :old_record,
    :timestamp
  ]

  @spec from_msg(tuple(), tuple(), decode :: boolean()) :: t()
  def from_msg(
        msg_insert(data: data),
        msg_relation(columns: columns, namespace: ns, name: name),
        decode?
      ) do
    %__MODULE__{
      type: :insert,
      namespace: ns,
      schema: into_schema(columns),
      table: name,
      record: cast(data, columns, decode?),
      old_record: %{}
    }
  end

  def from_msg(
        msg_update(change_data: data, old_data: old_data),
        msg_relation(columns: columns, namespace: ns, name: name),
        decode?
      ) do
    %__MODULE__{
      type: :update,
      namespace: ns,
      table: name,
      schema: into_schema(columns),
      record: cast(data, columns, decode?),
      old_record: cast(columns, old_data, decode?)
    }
  end

  def from_msg(
        msg_delete(old_data: data),
        msg_relation(columns: columns, namespace: ns, name: name),
        decode?
      ) do
    %__MODULE__{
      type: :delete,
      namespace: ns,
      schema: into_schema(columns),
      table: name,
      record: %{},
      old_record: cast(data, columns, decode?)
    }
  end

  defp into_schema(columns) do
    for c <- columns do
      c
      |> column()
      |> Enum.into(%{})
    end
  end

  defp cast(data, columns, decode?) do
    Enum.zip_reduce([data, columns], %{}, fn [text, typeinfo], acc ->
      key = column(typeinfo, :name)

      value =
        if decode? do
          t =
            typeinfo
            |> column(:type)
            |> PgType.type_info()

          PgType.decode(text, t)
        else
          text
        end

      Map.put(acc, key, value)
    end)
  end
end
