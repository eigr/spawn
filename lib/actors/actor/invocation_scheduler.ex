defmodule Actors.Actor.InvocationScheduler do
  use GenServer, restart: :transient
  use Retry

  require Logger

  alias Actors.Registry.ActorRegistry
  alias Eigr.Functions.Protocol.InvocationRequest

  @impl true
  def init(_arg) do
    {:ok, %{}, {:continue, :init_invocations}}
  end

  @impl true
  def handle_continue(:init_invocations, state) do
    stored_invocations = ActorRegistry.get_all_invocations()

    Enum.each(stored_invocations, &call_invoke/1)

    {:noreply, state}
  end

  @impl true
  def handle_info({:invoke, decoded_request}, state) do
    ActorRegistry.remove_invocation_request(
      decoded_request.actor.id.name,
      InvocationRequest.encode(decoded_request)
    )

    spawn(fn ->
      request_to_invoke = %InvocationRequest{decoded_request | scheduled_to: nil, async: true}
      Actors.invoke(request_to_invoke)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:schedule, request}, state) do
    encoded_request = InvocationRequest.encode(request)

    ActorRegistry.register_invocation_request(request.actor.id.name, encoded_request)

    call_invoke(request)

    {:noreply, state}
  end

  defp call_invoke(encoded_request) when is_binary(encoded_request) do
    InvocationRequest.decode(encoded_request) |> call_invoke()
  end

  defp call_invoke(%InvocationRequest{} = decoded_request) do
    delay_in_ms =
      decoded_request.scheduled_to
      |> DateTime.from_unix!(:millisecond)
      |> DateTime.diff(DateTime.utc_now(), :millisecond)

    if delay_in_ms <= 0 do
      Logger.warn("Received negative delayed invocation request (#{delay_in_ms}), invoking now")
      Process.send(self(), {:invoke, decoded_request}, [])
    else
      Process.send_after(self(), {:invoke, decoded_request}, delay_in_ms)
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
