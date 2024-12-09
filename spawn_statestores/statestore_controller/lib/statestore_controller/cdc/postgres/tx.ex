defmodule StatestoreController.CDC.Postgres.Tx do
  @moduledoc """

  """
  alias Postgrex.PgOutput.Lsn

  import Postgrex.PgOutput.Messages

  alias StatestoreController.CDC.Postgres.Tx.Operation

  @type t :: %__MODULE__{
          operations: [Operation.t()],
          relations: map(),
          timestamp: term(),
          xid: pos_integer(),
          state: :begin | :commit,
          lsn: Lsn.t(),
          end_lsn: Lsn.t()
        }

  defstruct [
    :timestamp,
    :xid,
    :lsn,
    :end_lsn,
    relations: %{},
    operations: [],
    state: :begin,
    decode: true
  ]

  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  def finalize(%__MODULE__{state: :commit, operations: ops} = tx) do
    %{tx | operations: Enum.reverse(ops)}
  end

  def finalize(%__MODULE__{} = tx), do: tx

  @spec build(t(), tuple()) :: t()
  def build(tx, msg_xlog_data(data: data)) do
    build(tx, data)
  end

  def build(tx, msg_begin(lsn: lsn, timestamp: ts, xid: xid)) do
    %{tx | lsn: lsn, timestamp: ts, xid: xid, state: :begin}
  end

  def build(%__MODULE__{state: :begin, relations: relations} = tx, msg_relation(id: id) = rel) do
    %{tx | relations: Map.put(relations, id, rel)}
  end

  def build(%__MODULE__{state: :begin, lsn: tx_lsn} = tx, msg_commit(lsn: lsn, end_lsn: end_lsn))
      when tx_lsn == lsn do
    %{tx | state: :commit, end_lsn: end_lsn}
  end

  def build(%__MODULE__{state: :begin} = builder, msg_insert(relation_id: id) = msg),
    do: build_op(builder, id, msg)

  def build(%__MODULE__{state: :begin} = builder, msg_update(relation_id: id) = msg),
    do: build_op(builder, id, msg)

  def build(%__MODULE__{state: :begin} = builder, msg_delete(relation_id: id) = msg),
    do: build_op(builder, id, msg)

  # skip unknown messages
  def build(%__MODULE__{} = tx, _msg), do: tx

  defp build_op(%__MODULE__{state: :begin, relations: rels, decode: decode} = tx, id, msg) do
    rel = Map.fetch!(rels, id)
    op = Operation.from_msg(msg, rel, decode)

    %{tx | operations: [op | tx.operations]}
  end
end
