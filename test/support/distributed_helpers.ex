defmodule Spawn.DistributedHelpers do
  def loop_until_ok(func, timeout \\ 10_000) do
    task = Task.async(fn -> do_loop(func, func.()) end)

    Task.await(task, timeout)
  end

  defp do_loop(_func, {:ok, term}), do: {:ok, term}

  defp do_loop(func, _resp) do
    do_loop(func, func.())
  rescue
    _ -> do_loop(func, func.())
  catch
    _ -> do_loop(func, func.())
  end
end
