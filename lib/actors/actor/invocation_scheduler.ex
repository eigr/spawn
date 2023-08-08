defmodule Actors.Actor.InvocationScheduler do
  @moduledoc """
  `InvocationScheduler` is a global process for the cluster that controls
  all Actions of type Schedule.
  This process is global to allow that even after restarts of a process or restart
  of an application we will still be able to perform invocations to actors,
  without the need for persistent storage such as a database.
  """
  use GenServer, restart: :transient
  use Retry

  require Logger

  alias Actors.Registry.ActorRegistry
  alias Eigr.Functions.Protocol.InvocationRequest

  @hibernate_delay 20_000
  @hibernate_jitter 30_000

  @impl true
  def init(_arg) do
    Process.flag(:trap_exit, true)
    Process.flag(:message_queue_data, :off_heap)
    {:ok, %{}, {:continue, :init_invocations}}
  end

  @impl true
  def handle_continue(:init_invocations, state) do
    # TODO: Fix this module
    # schedule_hibernate()
    # stored_invocations = ActorRegistry.get_all_invocations()

    # Enum.each(stored_invocations, &call_invoke/1)

    {:noreply, state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.debug("InvocationScheduler down with reason (#{inspect(reason)})")
  end

  @impl true
  def handle_info({:invoke, decoded_request}, state) do
    ActorRegistry.remove_invocation_request(
      decoded_request.actor.id,
      InvocationRequest.encode(decoded_request)
    )

    spawn(fn ->
      request_to_invoke = %InvocationRequest{decoded_request | scheduled_to: nil, async: true}
      Actors.invoke(request_to_invoke)
    end)

    {:noreply, state}
  end

  def handle_info(:hibernate, state) do
    schedule_hibernate()
    {:noreply, state, :hibernate}
  end

  @impl true
  def handle_cast({:schedule, request}, state) do
    encoded_request = InvocationRequest.encode(request)

    spawn(fn ->
      ActorRegistry.register_invocation_request(request.actor.id, encoded_request)
    end)

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

  defp schedule_hibernate() do
    Process.send_after(self(), :hibernate, next_hibernate_delay())
  end

  def next_hibernate_delay(), do: @hibernate_delay + :rand.uniform(@hibernate_jitter)

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
