defmodule SpawnSdk.Defact do
  @moduledoc """
  Define actions like a Elixir functions
  """

  @defact_actions_exports :__defact_actions_exports__
  @defact_timer_actions_exports :__defact_timer_actions_exports__

  defmacro defact(call, do: block) do
    define_defact(:def, call, block, __CALLER__)
  end

  defp define_defact(kind, call, block, env) do
    # TODO some magic here
    IO.inspect(kind, label: "kind")
    IO.inspect(call, label: "call")
    IO.inspect(block, label: "block")
    IO.inspect(env, label: "env")

    {name, args} = decompose_call!(kind, call, env)
    IO.inspect(name, label: "Name")
    IO.inspect(args, label: "args")
    arity = length(args)

    #if length(arity) <= 0, do: raise(ArgumentError)

    # TODO PUT Actions and TimerActions functions in Modules attributes

    quote bind_quoted: [
            name: name,
            args: args,
            block: block
          ] do
      def unquote(name)(unquote(args)), do: unquote(block)
    end
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

  defp compile_error!(env, description) do
    raise CompileError, line: env.line, file: env.file, description: description
  end
end
