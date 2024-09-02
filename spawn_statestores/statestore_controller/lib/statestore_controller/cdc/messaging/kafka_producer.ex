defmodule StatestoreController.CDC.Messaging.KafkaProducer do
  @moduledoc false
  require Logger

  @behaviour StatestoreController.CDC.Producer

  @impl true
  @spec is_alive?() :: boolean()
  def is_alive?() do
    KafkaEx.metadata()
    true
  catch
    :exit, details ->
      Logger.error("Kafka broker is down or we can't connect to it!. #{inspect(details)}")

      false
  end

  @impl true
  @spec produce(String.t(), any(), Keyword.t()) ::
          nil
          | :ok
          | {:ok, integer}
          | {:error, :closed}
          | {:error, :inet.posix()}
          | {:error, any}
          | :leader_not_available
          | {:error, :cannot_produce, any()}
  def produce(topic, data, opts \\ []) do
    nil
  end
end
