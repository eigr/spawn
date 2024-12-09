defmodule SpawnSdk.Defact do
  @moduledoc """
  Define actions like a Elixir functions

  ### Internal :defact_exports metadata saved as
  [
    {action_name, %{timer: 10_000}},
    {action_name2, %{timer: nil}}
  ]
  """

  @default_actions ~w(get Get get_state getState GetState)

  defmacro __using__(_args) do
    quote do
      import SpawnSdk.Defact

      Module.register_attribute(__MODULE__, :defact_exports, accumulate: true)

      @set_timer nil
    end
  end

  defmacro init(block_fn) do
    action_name = "init"

    define_action(action_name, block_fn)
  end

  defmacro action(action_name, opts, block_fn) do
    define_action(action_name, block_fn, opts)
  end

  defmacro action(action_name, block_fn) do
    define_action(action_name, block_fn)
  end

  defp define_action(action_name, block_fn, opts \\ []) do
    if action_name in @default_actions do
      raise SpawnSdk.Actor.MalformedActor, "Action name #{action_name} is reserved"
    end

    quote do
      Module.put_attribute(
        __MODULE__,
        :defact_exports,
        Macro.escape({unquote(action_name), %{timer: Keyword.get(unquote(opts), :timer)}})
      )

      def handle_action({unquote(action_name), payload}, context) do
        try do
          case {:erlang.fun_info(unquote(block_fn), :arity), unquote(action_name)} do
            {{:arity, 1}, _name} ->
              unquote(block_fn).(context)

            {{:arity, 2}, action} when action not in ~w(init Init Setup setup) ->
              unquote(block_fn).(context, payload)

            {{:arity, arity}, _} ->
              raise SpawnSdk.Actor.MalformedActor,
                    "Invalid callback arity #{arity} needs to be in (1, 2) for action=#{unquote(action_name)}"
          end
          |> case do
            %SpawnSdk.Value{} = value ->
              value

            {:reply, %SpawnSdk.Value{} = value} ->
              value

            _ ->
              raise SpawnSdk.Actor.MalformedActor,
                    "Return value for action=#{unquote(action_name)} must be a %Value{} struct"
          end
        rescue
          e ->
            reraise SpawnSdk.Actor.MalformedActor,
                    [
                      message: "Error in action=#{unquote(action_name)} error=#{inspect(e)}",
                      exception: e
                    ],
                    __STACKTRACE__
        end
      end
    end
  end

  defmacro defact(call, do: block) do
    define_defact(:def, call, block, __CALLER__)
  end

  defp define_defact(kind, call, block, env) do
    {name, args} = decompose_call!(kind, call, env)

    {payload, context} =
      case args do
        [payload, context] -> {payload, context}
        [context] -> {nil, context}
      end

    if is_nil(payload) do
      quote do
        Module.put_attribute(
          __MODULE__,
          :defact_exports,
          Macro.escape({unquote(name), %{timer: @set_timer}})
        )

        def handle_action({unquote(name), _}, unquote(context)) do
          unquote(block)
        end
      end
    else
      quote do
        Module.put_attribute(
          __MODULE__,
          :defact_exports,
          Macro.escape({unquote(name), %{timer: @set_timer}})
        )

        def handle_action({unquote(name), unquote(payload)}, unquote(context)) do
          unquote(block)
        end
      end
    end
  end

  defp decompose_call!(kind, {:when, _, [call, _guards]}, env),
    do: decompose_call!(kind, call, env)

  defp decompose_call!(_kind, {{:unquote, _, [name]}, _, args}, _env) do
    {parse_action_name(name), args}
  end

  defp decompose_call!(kind, call, env) do
    case Macro.decompose_call(call) do
      {name, args} ->
        {parse_action_name(name), args}

      :error ->
        compile_error!(
          env,
          "first argument of #{kind}n must be a call, got: #{Macro.to_string(call)}"
        )
    end
  end

  defp parse_action_name(action) when is_atom(action), do: Atom.to_string(action)
  defp parse_action_name(action) when is_binary(action), do: action

  defp compile_error!(env, description) do
    raise CompileError, line: env.line, file: env.file, description: description
  end
end
