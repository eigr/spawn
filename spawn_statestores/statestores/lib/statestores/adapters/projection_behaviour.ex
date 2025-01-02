defmodule Statestores.Adapters.ProjectionBehaviour do
  @moduledoc """
  Defines the default behavior for each Projection Provider.
  """

  @type projection_type :: module()
  @type table_name :: String.t()
  @type data :: struct()
  @type query :: String.t()
  @type params :: struct()
  @type opts :: Keyword.t()

  @callback create_or_update_table(projection_type(), table_name()) :: :ok

  @callback upsert(projection_type(), table_name(), data()) :: :ok

  @callback query(projection_type(), query(), params(), opts()) ::
              {:error, term()} | {:ok, data()}

  @callback default_port :: <<_::32>>

  defmacro __using__(_opts) do
    quote do
      alias Statestores.Adapters.ProjectionBehaviour
      import Statestores.Util, only: [init_config: 1, generate_key: 1]

      @behaviour Statestores.Adapters.ProjectionBehaviour

      def init(_type, config), do: init_config(config)
    end
  end
end
