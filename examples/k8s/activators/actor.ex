defmodule MyProcessActor do
  use GenServer

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:some_command, payload}, _from, state) do
    # ...
    {:reply, do_something_and_response_back(payload), %{state | some_attribute: new_value}}
  end

end
