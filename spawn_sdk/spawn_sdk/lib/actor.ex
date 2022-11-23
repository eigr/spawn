defmodule SpawnSdk.Actor do
  @moduledoc """
  Documentation for `Actor`.

  Actor look like this:

    defmodule MyActor do
      use SpawnSdk.Actor,
        name: "joe",
        persistent: false,
        state_type: Io.Eigr.Spawn.Example.MyState,
        deactivate_timeout: 5_000,
        snapshot_timeout: 2_000

      require Logger
      alias Io.Eigr.Spawn.Example.{MyState, MyBusinessMessage}

      defact sum(%MyBusinessMessage{value: value} = data}, %Context{state: state} = ctx) do
        Logger.info("Received Request...")

        new_value = (state.value || 0) + value

        %Value{}
        |> Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
        |> Value.reply!()
      end
  """

  alias SpawnSdk.{Context, Value}

  @type command :: String.t()

  @type context :: Context.t()

  @type data :: module()

  @type error :: any()

  @type value :: Value.t()

  @callback handle_command({command(), data()}, context()) ::
              {:reply, value()} | {:error, error()} | {:error, error(), value()}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias SpawnSdk.{
        Context,
        Flow.Broadcast,
        Flow.Pipe,
        Flow.Forward,
        Flow.SideEffect,
        Value
      }

      import SpawnSdk.Actor
      use SpawnSdk.Defact

      import SpawnSdk.System.SpawnSystem,
        only: [
          invoke: 2,
          register: 2,
          spawn_actor: 2
        ]

      Module.register_attribute(__MODULE__, :actor_opts, persist: true)
      Module.put_attribute(__MODULE__, :actor_opts, opts)

      @behaviour SpawnSdk.Actor
      @before_compile SpawnSdk.Actor
    end
  end

  defmacro __before_compile__(_a) do
    opts = Module.get_attribute(__CALLER__.module, :actor_opts)
    actions = Module.get_attribute(__CALLER__.module, :defact_exports)

    actor_kind = Keyword.get(opts, :kind, :SINGLETON)
    actor_name = Keyword.get(opts, :name, Atom.to_string(__CALLER__.module))
    caller_module = __CALLER__.module
    channel_group = Keyword.get(opts, :channel, nil)

    state_type = Keyword.get(opts, :state_type, nil)
    stateful = Keyword.get(opts, :stateful, true)

    if stateful and !Code.ensure_loaded?(Statestores.Supervisor) do
      raise """
      ArgumentError. You need to add :spawn_statestores to your dependency if you are going to use persistent actors.
      Otherwise, set `stateful: false` in your Actor attributes
      """
    end

    if state_type == nil and stateful do
      raise "ArgumentError. State type is mandatory if stateful is true"
    end

    deactivate_timeout = Keyword.get(opts, :deactivate_timeout, 10_000)
    snapshot_timeout = Keyword.get(opts, :snapshot_timeout, 2_000)

    quote do
      def __meta__(:actions) do
        unquote(actions)
        |> Enum.filter(fn {_action, %{timer: timer}} -> is_nil(timer) end)
        |> Enum.map(fn {action, %{timer: timer}} -> action end)
      end

      def __meta__(:timers) do
        unquote(actions)
        |> Enum.reject(fn {_action, %{timer: timer}} -> is_nil(timer) end)
        |> Enum.map(fn {action, %{timer: timer}} -> {action, timer} end)
      end

      def __meta__(:channel), do: unquote(channel_group)

      def __meta__(:name) do
        actor_name = unquote(actor_name)
        kind = unquote(actor_kind)

        if kind == :ABSTRACT do
          unless :persistent_term.get("actor:#{actor_name}", false) do
            :persistent_term.put("actor:#{actor_name}", unquote(caller_module))
          end

          actor_name
        else
          actor_name
        end
      end

      def __meta__(:stateful), do: unquote(stateful)
      def __meta__(:kind), do: unquote(actor_kind)
      def __meta__(:state_type), do: unquote(state_type)
      def __meta__(:snapshot_timeout), do: unquote(snapshot_timeout)
      def __meta__(:deactivate_timeout), do: unquote(deactivate_timeout)
    end
  end
end
