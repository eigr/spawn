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

    Node.self()
    |> InvocationSchedulerState.all()
    |> Enum.each(&call_invoke/1)

    {:noreply, state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.debug("InvocationScheduler down with reason (#{inspect(reason)})")
  end

  @impl true
  def handle_info({:invoke, decoded_request, repeat_in}, state) do
    if is_nil(repeat_in) do
      scheduled_to =
        DateTime.utc_now()
        |> DateTime.add(repeat_in, :millisecond)

      request = %InvocationRequest{decoded_request | scheduled_to: scheduled_to}

      GenServer.cast(self(), {:schedule, request, repeat_in, false})
    else
      InvocationSchedulerState.remove(
        Node.self(),
        {InvocationRequest.encode(decoded_request), nil}
      )
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
  def handle_cast({:schedule, request, repeat_in, set_state?}, state) do
    if set_state? do
      encoded_request = InvocationRequest.encode(request)

      InvocationSchedulerState.put(encoded_request, repeat_in)
    end

    call_invoke({request, repeat_in})

    {:noreply, state}
  end

  @impl true
  def handle_cast({:schedule_many, requests}, state) do
    requests =
      Enum.map(requests, fn {request, repeat_in} ->
        encoded_request = InvocationRequest.encode(request)

        call_invoke({request, repeat_in})

        {encoded_request, repeat_in}
      end)

    InvocationSchedulerState.put_many(requests)

    {:noreply, state}
  end

  defp call_invoke({encoded_request, repeat_in}) when is_binary(encoded_request) do
    decoded = encoded_request |> InvocationRequest.decode()

    call_invoke({decoded, repeat_in})
  end

  defp call_invoke({%InvocationRequest{} = decoded_request, repeat_in}) do
    delay_in_ms =
      decoded_request.scheduled_to
      |> DateTime.from_unix!(:millisecond)
      |> DateTime.diff(DateTime.utc_now(), :millisecond)

    if delay_in_ms <= 0 do
      Logger.warn("Received negative delayed invocation request (#{delay_in_ms}), invoking now")
      Process.send(self(), {:invoke, decoded_request, repeat_in}, [])
    else
      Process.send_after(self(), {:invoke, decoded_request, repeat_in}, delay_in_ms)
    end
  end

  defp schedule_hibernate() do
    Process.send_after(self(), :hibernate, next_hibernate_delay())
  end

  def next_hibernate_delay(), do: @hibernate_delay + :rand.uniform(@hibernate_jitter)

  # Client

  def schedule_invocations(requests) do
    GenServer.cast({:global, __MODULE__}, {:schedule_many, requests})
  end

  def schedule_invoke(%InvocationRequest{} = invocation_request, repeat_in \\ nil) do
    GenServer.cast({:global, __MODULE__}, {:schedule, invocation_request, repeat_in, true})
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
