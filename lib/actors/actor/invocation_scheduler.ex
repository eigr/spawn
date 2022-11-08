defmodule Actors.Actor.InvocationScheduler do
  use GenServer, restart: :transient
  use Retry

  require Logger

  alias Actors.Registry.ActorRegistry
  alias Eigr.Functions.Protocol.InvocationRequest

  @impl true
  def init(_) do


    {:ok, %{}}
  end

  def handle_info({:invoke, request}, state) do
    retry with: exponential_backoff() |> randomize |> expiry(10_000),
          atoms: [:error, :exit, :noproc, :erpc, :noconnection],
          rescue_only: [ErlangError] do
      StateManager.remove_invoke_request(request)
    after
      decoded_request = InvocationRequest.decode(request)

      spawn(fn ->
        Actors.invoke(%{decoded_request | async: true})
      end)

      {:noreply, Map.delete(state, request)}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:schedule, scheduled_to, encoded_request}, state) do
    call_invoke(scheduled_to, encoded_request)

    {:noreply, state}
  end

  defp call_invoke(scheduled_to, encoded_request) do
    delay_in_ms = DateTime.diff(scheduled_to, DateTime.utc_now(), :millisecond)

    if delay_in_ms <= 0 do
      Logger.warn("Received negative delayed invocation request (#{delay_in_ms}), invoking now")
      Process.send(self(), {:invoke, encoded_request})
    else
      Process.send_after(self(), {:invoke, encoded_request}, delay_in_ms)
    end
  end

  # Client

  def schedule_invoke(%InvocationRequest{} = invocation_request, delay_ms)
      when is_integer(delay_ms) do
    scheduled_to = DateTime.add(DateTime.utc_now(), delay_ms, :millisecond)
    schedule_invoke(invocation_request, scheduled_to)
  end

  def schedule_invoke(%InvocationRequest{} = invocation_request, scheduled_to) do
    request = InvocationRequest.encode(invocation_request)

    GenServer.cast(__MODULE__, {:schedule, scheduled_to, request})
  end

  def child_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      restart: :transient
    }
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
end
