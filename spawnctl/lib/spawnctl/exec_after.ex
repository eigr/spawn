defmodule SpawnCtl.GroupExecAfter do
  use GenServer

  @impl true
  def init(_init_arg) do
    {:ok, %{timer_ref: nil}}
  end

  @impl true
  def handle_call({:exec, callback, wait_for}, _from, state) do
    if state.timer_ref do
      {:reply, :ok, state}
    else
      ref = Process.send_after(self(), {:callback, callback}, wait_for)

      {:reply, :ok, %{state | timer_ref: ref}}
    end
  end

  @impl true
  def handle_info({:callback, callback}, state) do
    spawn(fn ->
      callback.()
    end)

    {:noreply, %{state | timer_ref: nil}}
  end

  def exec(callback, wait_for \\ 500) do
    GenServer.call(__MODULE__, {:exec, callback, wait_for})
  end

  @doc false
  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)
end

