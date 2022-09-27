defmodule SpawnSdk.Actor do
  @moduledoc """
  Documentation for `Actor`.

  Actor look like this:

    defmodule MyActor do
      use SpawnSdk.Actor,
        name: "joe",
        persistent: false
        state_type: MyActorStateModule,
        deactivate_timeout: 5_000,
        snapshot_timeout: 2_000

      @impl true
      handle_command({:sum, %MyPayloadProtobufModule{} = _data}, ctx) do
        current_state = ctx.state
        new_state = current_state

        response = %MyResponseProtobufModule{}
        result = %Value{state: new_state, value: response}

        {:ok, result}
      end
  """

  alias SpawnSdk.{Context, Value}

  @type command :: atom()

  @type context :: Context.t()

  @type data :: module()

  @type error :: any()

  @type value :: Value.t()

  @callback handle_command({command(), data()}, context()) ::
              {:ok, value()} | {:error, error()} | {:error, error(), value()}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      alias SpawnSdk.{Context, Value}

      import SpawnSdk.Actor
      import SpawnSdk.System.SpawnSystem

      @behaviour SpawnSdk.Actor

      actor_name = Keyword.fetch!(opts, :name)
      state_type = Keyword.fetch!(opts, :state_type)
      persistent = Keyword.get(opts, :persistent, true)

      snapshot_timeout = Keyword.get(opts, :snapshot_timeout, 10_000)
      deactivate_timeout = Keyword.get(opts, :deactivate_timeout, 30_000)

      def __name__(), do: unquote(actor_name)
      def __persistent__(), do: unquote(persistent)
      def __state_type__(), do: unquote(state_type)
      def __snapshot_timeout__(), do: unquote(snapshot_timeout)
      def __deactivate_timeout__(), do: unquote(deactivate_timeout)
    end
  end
end
