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

      @impl true
      def handle_command(
            {:sum, %MyBusinessMessage{value: value} = data},
            %Context{state: state} = ctx
          ) do
        Logger.info("Received Request...")

        new_value = (state.value || 0) + value

        %Value{}
        |> Value.of(%MyBusinessMessage{value: new_value}, %MyState{value: new_value})
        |> Value.reply!()
      end
  """

  alias SpawnSdk.{Context, Value}

  @type command :: atom()

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
        Flow.SideEffect,
        Value
      }

      import SpawnSdk.Actor

      import SpawnSdk.System.SpawnSystem,
        only: [
          invoke: 2,
          register: 2,
          spawn_actor: 2
        ]

      @behaviour SpawnSdk.Actor

      abstract_actor = Keyword.get(opts, :abstract, false)
      actions = Keyword.get(opts, :actions, [])
      actor_name = Keyword.get(opts, :name, Atom.to_string(__MODULE__))
      channel_group = Keyword.get(opts, :channel, nil)
      persistent = Keyword.get(opts, :persistent, true)
      state_type = Keyword.fetch!(opts, :state_type)
      timers = Keyword.get(opts, :timers, [])

      deactivate_timeout = Keyword.get(opts, :deactivate_timeout, 10_000)
      snapshot_timeout = Keyword.get(opts, :snapshot_timeout, 2_000)

      def __meta__(:actions), do: unquote(actions)
      def __meta__(:channel), do: unquote(channel_group)
      def __meta__(:name), do: unquote(actor_name)
      def __meta__(:persistent), do: unquote(persistent)
      def __meta__(:abstract), do: unquote(abstract_actor)
      def __meta__(:state_type), do: unquote(state_type)
      def __meta__(:snapshot_timeout), do: unquote(snapshot_timeout)
      def __meta__(:deactivate_timeout), do: unquote(deactivate_timeout)
      def __meta__(:timers), do: unquote(timers)
    end
  end
end
