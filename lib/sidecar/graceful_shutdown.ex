defmodule Sidecar.GracefulShutdown do
  @moduledoc """
  This module was copied and adapted from this project https://github.com/straw-hat-team/beam-monorepo

  Catches `SIGTERM` signal to gracefully stop the system.
  By default, a `SIGTERM` signal triggers a `System.stop/0`. When running in a Kubernetes-managed cluster or an
  infrastructure alike, the nodes will be joining and leaving the cluster when auto-scaling is enabled or when deploying
  new version of the application.
  You should let the system to gracefully stop in combination with readiness probe you can make sure that the system is
  ready to stop without a relying on a `SIGKILL` signal.

  You can read more about this at [Termination of Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination).
  When a `SIGTERM` is received, the handler enters "connection draining mode", during which `get_status/0` starts
  returning `:draining` status, and then, after a delay, the handler calls `System.stop/1`, carefully halting the Erlang VM
  and starts returning `:stopping` status.
  """

  defmodule State do
    @moduledoc false

    defstruct init_stop?: true, shutdown_delay_ms: 130_000, notify_pid: nil

    def new(opts) do
      Map.merge(%__MODULE__{}, Enum.into(opts, %{}))
    end
  end

  alias Sidecar.GracefulShutdown.State

  @behaviour :gen_event

  @ets_table Module.concat(__MODULE__, EtsTable)

  @typedoc """
  Configuration options for the server.
  - `shutdown_delay_ms`: milliseconds before draining the VM after `SIGTERM`. milliseconds between start of connection draining
      and ordered shut-down using `System.stop/0`.
  - `notify_pid`: process ID to notify when the server started draining.
  - `init_stop?`: whether to call `:System.stop/1` when a `SIGTERM` is received. Useful for testing since we don't want
      to stop the VM when testing. **Be careful when using this option since it should always be `true` in production.**
  """
  @type opts :: [shutdown_delay_ms: non_neg_integer(), init_stop?: boolean, notify_pid: pid()]

  @typedoc """
  The state of system.
  - `:draining` - the node is draining and will be shutdown after the delay.
  - `:stopping` - the node is shutting down.
  - `:running` - the node is accepting work.
  """
  @type status :: :running | :draining | :stopping

  require Logger

  @doc """
  Returns the status of the system.
  """
  @spec get_status :: status()
  def get_status do
    [status: status] = :ets.lookup(@ets_table, :status)
    status
  end

  @doc """
  Returns true if the system is in the `:running` status.
  """
  @spec running? :: boolean()
  def running? do
    :running == get_status()
  end

  @doc """
  Returns a specification to start `#{inspect(__MODULE__)}` under a supervisor.
  See the "Child specification" section in the Supervisor module for more detailed information.
  """
  @spec child_spec(opts :: opts()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc false
  def start_link(opts \\ []) do
    :ok =
      :gen_event.swap_sup_handler(
        :erl_signal_server,
        {:erl_signal_handler, []},
        {__MODULE__, opts}
      )

    # Returns `ignore` since this doesn't actually start a process itself, it gets the `gen_event` server to start one.
    :ignore
  end

  @impl :gen_event
  def init({opts, :ok}) do
    create_ets_table()
    set_status(:running)
    {:ok, State.new(opts)}
  end

  def init({_opts, error}) do
    {:error, error}
  end

  @impl :gen_event
  def handle_event(:sigterm, state) do
    Logger.info("Received SIGTERM, draining the system...")
    set_status_and_notify(state, :draining)
    send_stop(state)
    spawn(fn -> Supervisor.stop(Sidecar.ProcessSupervisor, :normal, state.shutdown_delay_ms) end)

    {:ok, state}
  end

  @impl :gen_event
  def handle_event(msg, state) do
    # Proxy all the events that are not `SIGTERM` to the default implementation of `:erl_signal_handler`.
    :erl_signal_handler.handle_event(msg, state)
    {:ok, state}
  end

  @impl :gen_event
  def handle_info(:stop, state) do
    Logger.info("Stopping application...")
    if state.init_stop?, do: System.stop()
    set_status_and_notify(state, :stopping)
    {:ok, state}
  end

  @impl :gen_event
  def handle_info(_msg, state), do: {:ok, state}

  @impl :gen_event
  def handle_call(_, state) do
    {:ok, :ok, state}
  end

  @impl :gen_event
  def terminate(_args, _state) do
    true = :ets.delete(@ets_table)
    :ok
  end

  defp set_status_and_notify(state, status) do
    set_status(status)
    notify_pid(state, status)
  end

  defp set_status(status) do
    :ets.insert(@ets_table, {:status, status})
  end

  defp notify_pid(%{notify_pid: nil}, _msg) do
    :ok
  end

  defp notify_pid(%{notify_pid: notify_pid}, msg) do
    send(notify_pid, msg)
  end

  defp send_stop(state) do
    # Wait for the delay before stopping the system.
    Process.send_after(self(), :stop, state.shutdown_delay_ms)
  end

  defp create_ets_table do
    with :undefined <- :ets.info(@ets_table) do
      :ets.new(@ets_table, [:named_table, :public, read_concurrency: true])
    end
  end
end
