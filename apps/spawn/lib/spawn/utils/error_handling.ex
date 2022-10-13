defmodule Spawn.Utils.ErrorHandling do
  @moduledoc false
  require Logger

  def loop_until_ok(func, timeout \\ 10_000) do
    task = Task.async(fn -> do_loop(func, func.()) end)

    Task.await(task, timeout)
  end

  defp do_loop(_func, :ok), do: :ok

  defp do_loop(func, _resp) do
    do_loop(func, func.())
  rescue
    _ -> do_loop(func, func.())
  catch
    :exit, {:noproc, _} = error ->
      Logger.warning("Failure during node sync. Error: #{inspect(error)}")
      do_loop(func, func.())
  end
end
