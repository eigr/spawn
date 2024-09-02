defmodule StatestoreController.CDC.CdcSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias StatestoreController.CDC.Postgres.Replication
  alias StatestoreController.CDC.Postgres.MessageHandler

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      shutdown: 120_000
    }
  end

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    with {:ok, _pg} <- Postgrex.start_link(opts),
         {:ok, _cdc_pid} <- Replication.start_link(opts) do
      children = [
        {MessageHandler, opts}
      ]

      Supervisor.init(children, strategy: :rest_for_one)
    else
      _ ->
        Supervisor.init([], strategy: :rest_for_one)
    end
  end
end
