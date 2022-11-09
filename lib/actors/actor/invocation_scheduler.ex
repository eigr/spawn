defmodule Actors.Actor.InvocationScheduler do
  use GenServer, restart: :transient
  use Retry

  require Logger

  alias Actors.Registry.ActorRegistry
  alias Eigr.Functions.Protocol.InvocationRequest

  @impl true
  def init(_arg) do
    stored_invocations = ActorRegistry.get_all_invocations()

    Enum.each(stored_invocations, &call_invoke/1)

    {:ok, %{}}
  end

  @impl true
  def handle_info({:invoke, request}, state) do
    decoded_request = InvocationRequest.decode(request)

    retry with: exponential_backoff() |> randomize |> expiry(10_000),
          atoms: [:error, :exit, :noproc, :erpc, :noconnection],
          rescue_only: [ErlangError] do
      ActorRegistry.remove_invocation_request(decoded_request.actor.id.name, request)
    after
      _ ->
        spawn(fn ->
          Actors.invoke(%{decoded_request | scheduled_to: nil, async: true})
        end)

        {:noreply, state}
    else
      _ -> {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:schedule, request}, state) do
    encoded_request = InvocationRequest.encode(request)

    ActorRegistry.register_invocation_request(request.actor.id.name, encoded_request)

    call_invoke(encoded_request)

    {:noreply, state}
  end

  defp call_invoke(encoded_request) do
    decoded_request = InvocationRequest.decode(encoded_request)

    delay_in_ms =
      decoded_request.scheduled_to
      |> DateTime.from_unix!(:millisecond)
      |> DateTime.diff(DateTime.utc_now(), :millisecond)

    if delay_in_ms <= 0 do
      Logger.warn("Received negative delayed invocation request (#{delay_in_ms}), invoking now")
      Process.send(self(), {:invoke, encoded_request}, [:noconnect])
    else
      Process.send_after(self(), {:invoke, encoded_request}, delay_in_ms)
    end
  end

  # Client

  def schedule_invoke(%InvocationRequest{} = invocation_request) do
    GenServer.cast({:global, __MODULE__}, {:schedule, invocation_request})
  end

  def child_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      restart: :transient
    }
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__})
  end
end
