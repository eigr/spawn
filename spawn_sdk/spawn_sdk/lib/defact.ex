defmodule SpawnSdk.Defact do
  @moduledoc """
  Define actions like a Elixir functions
  """

  defmacro defact(call, do: block) do
    define_defact(:def, call, block, __CALLER__)
  end

  defp define_defact(kind, call, block, env) do
    # TODO some magic here
    {name, args} = decompose_call!(kind, call, env)
    arity = length(args)
  end

  defp decompose_call!(kind, {:when, _, [call, _guards]}, env),
    do: decompose_call!(kind, call, env)

  defp decompose_call!(_kind, {{:unquote, _, [name]}, _, args}, _env) do
    {name, args}
  end

  defp decompose_call!(kind, call, env) do
    case Macro.decompose_call(call) do
      {name, args} ->
        {name, args}

      :error ->
        compile_error!(
          env,
          "first argument of #{kind}n must be a call, got: #{Macro.to_string(call)}"
        )
    end
  end
end
