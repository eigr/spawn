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
      abstract_actor = Keyword.get(opts, :abstract, false)

      snapshot_timeout = Keyword.get(opts, :snapshot_timeout, 10_000)
      deactivate_timeout = Keyword.get(opts, :deactivate_timeout, 30_000)

      def __meta__(:name), do: unquote(actor_name)
      def __meta__(:persistent), do: unquote(persistent)
      def __meta__(:abstract), do: unquote(abstract_actor)
      def __meta__(:state_type), do: unquote(state_type)
      def __meta__(:snapshot_timeout), do: unquote(snapshot_timeout)
      def __meta__(:deactivate_timeout), do: unquote(deactivate_timeout)
    end
  end
end
