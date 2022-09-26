defmodule SpawnSdk.Actor do
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
