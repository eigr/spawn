defmodule StatestoreController.CDC.Postgres.MessageHandler do
  @moduledoc """

  """
  use GenServer
  require Logger

  alias StatestoreController.CDC.Postgres.Tx
  alias StatestoreController.CDC.Messaging.Producer

  @impl true
  def init(opts) do
    topic = Keyword.fetch!(opts, :sink_topic)
    tables = Keyword.fetch!(opts, :source_tables)
    {:ok, %{tables: tables, topic: topic}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def handle_cast(
        {:handle, %Tx{timestamp: timestamp, operations: operations} = transaction} = _msg,
        %{tables: tables, topic: topic} = state
      ) do
    Logger.debug("#{inspect(__MODULE__)} Received message: #{inspect(transaction)}")

    case Producer.alive?() do
      true ->
        Enum.filter(operations, fn op ->
          cond do
            is_nil(tables) ->
              true

            length(tables) > 0 ->
              Enum.member?(tables, op.table)

            true ->
              true
          end
        end)
        |> Enum.map(fn op ->
          to_data(timestamp, op)
          |> produces(topic, [])
        end)

      _ ->
        {:error, :unavailable, %{status: "Error Kafka is not available"}}
    end

    {:noreply, state}
  end

  def handle_cast(msg, state) do
    Logger.warn("Received an unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  def publish(tx) do
    GenServer.cast(__MODULE__, {:handle, tx})
  end

  defp to_data(
         timestamp,
         %StatestoreController.CDC.Postgres.Tx.Operation{
           type: op,
           namespace: namespace,
           table: table,
           record: record,
           old_record: old
         } = _operation
       ) do
    %{
      "timestamp" => DateTime.to_string(timestamp),
      "operation" => Atom.to_string(op),
      "schema" => namespace,
      "table" => table,
      "data_before" => old,
      "data_after" => record
    }
  end

  defp produces(payload, topic, opts) do
    case Producer.produce(topic, payload, opts) do
      :ok ->
        {:ok, %{status: "Ok"}}

      {:ok, partition} ->
        {:ok, %{status: "Ok", partition: partition}}

      {:error, :closed} ->
        {:error, :closed, %{status: "Error. Connection closed"}}

      :leader_not_available ->
        {:error, :leader_not_available, %{status: "Error. Kafka Node Leader is not available"}}

      {:error, :cannot_produce, error} ->
        {:error, :cannot_produce, %{status: "Error. #{inspect(error)}"}}

      {:error, error} ->
        {:error, %{status: "Error. #{inspect(error)}"}}

      error ->
        {:error, %{status: "Error. #{inspect(error)}"}}
    end
  end
end
