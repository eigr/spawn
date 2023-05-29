defmodule Statestores.Adapters.SnapshotBehaviour do
  @moduledoc """
  Defines the default behavior for each Statestore Provider.
  """
  alias Statestores.Schemas.Snapshot

  @type id :: String.t()

  @type event :: Snapshot.t()

  @callback get_by_key(id()) :: event()

  @callback save(event()) :: {:error, any} | {:ok, event()}

  @callback default_port :: <<_::32>>

  defmacro __using__(_opts) do
    quote do
      alias Statestores.Adapters.SnapshotBehaviour
      import Statestores.Util, only: [init_config: 1, generate_key: 1]

      @behaviour Statestores.Adapters.SnapshotBehaviour

      def init(_type, config), do: init_config(config)
    end
  end
end
