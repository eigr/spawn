defmodule StatestoreController.CDC.Postgres.Protocol do
  @moduledoc """

  """
  require Logger
  import Postgrex.PgOutput.Messages

  alias StatestoreController.CDC.Postgres.Protocol.Tx
  alias Postgrex.PgOutput.Lsn

  @type t :: %__MODULE__{
          tx: Tx.t(),
          relations: map()
        }

  defstruct [
    :tx,
    relations: %{}
  ]

  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  def handle_message(msg, state) when is_binary(msg) do
    msg
    |> decode()
    |> handle_message(state)
  end

  def handle_message(msg_primary_keep_alive(reply: 0), state), do: {[], nil, state}

  def handle_message(msg_primary_keep_alive(server_wal: lsn, reply: 1), state) do
    Logger.debug("msg_primary_keep_alive message reply=true")
    <<lsn::64>> = Lsn.encode(lsn)

    {[standby_status_update(lsn)], nil, state}
  end

  def handle_message(msg, %__MODULE__{tx: nil, relations: relations} = state) do
    tx =
      [relations: relations, decode: true]
      |> Tx.new()
      |> Tx.build(msg)

    {[], nil, %{state | tx: tx}}
  end

  def handle_message(msg, %__MODULE__{tx: tx} = state) do
    case Tx.build(tx, msg) do
      %Tx{state: :commit, relations: relations} ->
        tx = Tx.finalize(tx)
        relations = Map.merge(state.relations, relations)
        {[], tx, %{state | tx: nil, relations: relations}}

      tx ->
        {[], nil, %{state | tx: tx}}
    end
  end

  defp standby_status_update(lsn) do
    [
      wal_recv: lsn + 1,
      wal_flush: lsn + 1,
      wal_apply: lsn + 1,
      system_clock: now(),
      reply: 0
    ]
    |> msg_standby_status_update()
    |> encode()
  end
end
