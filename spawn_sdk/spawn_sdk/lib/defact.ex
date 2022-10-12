defmodule SpawnSdk.Defact do
  @moduledoc """
  Define actions like a Elixir functions
  """

  defmacro defact(call, do: block) do
    define_defact(:def, call, block, __CALLER__)
  end

  defp define_defact(kind, call, block, env) do
    # TODO some magic here
  end
end
