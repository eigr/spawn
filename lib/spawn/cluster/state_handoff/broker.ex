defmodule Spawn.StateHandoff.Broker do
  @behaviour :sbroker

  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent
    }
  end

  def start_link() do
    start_link(timeout: 10_000)
  end

  def start_link(opts) do
    :sbroker.start_link({:local, __MODULE__}, __MODULE__, opts, [])
  end

  def init(opts) do
    # Make the "left" side of the broker a FIFO queue that drops the request after the timeout is reached.
    max =
      if opts[:max] == -1 do
        :infinity
      else
        max
      end

    client_queue =
      {:sbroker_timeout_queue,
       %{
         out: :out,
         timeout: opts[:timeout],
         drop: :drop,
         min: opts[:min],
         max: max
       }}

    # Make the "right" side of the broker a FIFO queue that has no timeout.
    worker_queue =
      {:sbroker_drop_queue,
       %{
         out: :out_r,
         drop: :drop,
         timeout: :infinity
       }}

    {:ok, {client_queue, worker_queue, []}}
  end
end
