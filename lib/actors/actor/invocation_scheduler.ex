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

  alias Spawn.Cluster.StateHandoff.InvocationSchedulerState
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
    schedule_hibernate()

    InvocationSchedulerState.all()
    |> Enum.each(&call_invoke/1)

    {:noreply, state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.debug("InvocationScheduler down with reason (#{inspect(reason)})")
  end

  @impl true
  def handle_info({:invoke, decoded_request, scheduled_to, repeat_in}, state) do
    if is_nil(repeat_in) do
      InvocationSchedulerState.remove(InvocationRequest.encode(decoded_request))
    else
      scheduled_to = DateTime.add(scheduled_to, repeat_in, :millisecond)

      GenServer.cast(self(), {:schedule, decoded_request, scheduled_to, repeat_in})
    end

    request_to_invoke = %InvocationRequest{decoded_request | scheduled_to: 0, async: true}
    Actors.invoke(request_to_invoke)

    {:noreply, state}
  end

  def handle_info(:hibernate, state) do
    schedule_hibernate()
    {:noreply, state, :hibernate}
  end

  @impl true
  def handle_cast({:schedule, request, scheduled_to, repeat_in}, state) do
    encoded_request =
      InvocationRequest.encode(%InvocationRequest{request | scheduled_to: 0, async: true})

    InvocationSchedulerState.put(encoded_request, scheduled_to, repeat_in)

    call_invoke({request, {scheduled_to, repeat_in}})

    {:noreply, state}
  end

  @impl true
  def handle_cast({:schedule_fixed, requests}, state) do
    requests =
      Enum.reduce(requests, [], fn {request, scheduled_to, repeat_in}, acc ->
        encoded_request = InvocationRequest.encode(request)

        if is_nil(InvocationSchedulerState.get(encoded_request)) do
          call_invoke({request, {scheduled_to, repeat_in}})

          acc ++ [{encoded_request, scheduled_to, repeat_in}]
        else
          acc
        end
      end)

    InvocationSchedulerState.put_many(requests)

    {:noreply, state}
  end

  defp call_invoke({encoded_request, {scheduled_to, repeat_in}})
       when is_binary(encoded_request) do
    decoded = encoded_request |> InvocationRequest.decode()

    call_invoke({decoded, {scheduled_to, repeat_in}})
  end

  defp call_invoke({%InvocationRequest{} = decoded_request, {scheduled_to, repeat_in}}) do
    scheduled_to = get_scheduled_to_datetime(scheduled_to)
    delay_in_ms = DateTime.diff(scheduled_to, DateTime.utc_now(), :millisecond)

    if delay_in_ms <= 0 do
      Logger.warning(
        "Received negative delayed invocation request (#{delay_in_ms}), invoking now"
      )

      Process.send(self(), {:invoke, decoded_request, scheduled_to, repeat_in}, [])
    else
      Process.send_after(self(), {:invoke, decoded_request, scheduled_to, repeat_in}, delay_in_ms)
    end
  end

  defp schedule_hibernate() do
    Process.send_after(self(), :hibernate, next_hibernate_delay())
  end

  defp get_scheduled_to_datetime(scheduled_to) when is_number(scheduled_to) do
    scheduled_to
    |> DateTime.from_unix!(:millisecond)
  end

  defp get_scheduled_to_datetime(scheduled_to), do: scheduled_to

  def next_hibernate_delay(), do: @hibernate_delay + :rand.uniform(@hibernate_jitter)

  # Client

  def schedule_fixed_invocations(requests) do
    GenServer.cast({:global, __MODULE__}, {:schedule_fixed, requests})
  end

  def schedule_invoke(%InvocationRequest{} = invocation_request, repeat_in \\ nil) do
    GenServer.cast(
      {:global, __MODULE__},
      {:schedule, invocation_request, invocation_request.scheduled_to, repeat_in}
    )
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
