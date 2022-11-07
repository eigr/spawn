defmodule Actors.Actor.InvocationScheduler do
  use GenServer, restart: :transient
  use Retry

  require Logger

  alias Actors.Actor.StateManager
  alias Eigr.Functions.Protocol.InvocationRequest

  @impl true
  def init(_) do
    # call statestore

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
            end

    {:noreply, Map.delete(state, request)}
  end

  def handle_cast({:schedule, scheduled_to, encoded_request}, state) do
    Process.send_after(self(), {:invoke, encoded_request}, )

    {:noreply, state}
  end

  # Client

  def schedule_invoke(%InvocationRequest{} = invocation_request, delay_ms) when is_integer(delay_ms) do
    scheduled_to = DateTime.utc_now() |> DateTime.add(delay_ms, :millisecond)
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
