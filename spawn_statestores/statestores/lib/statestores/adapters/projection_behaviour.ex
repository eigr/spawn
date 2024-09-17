defmodule Statestores.Adapters.ProjectionBehaviour do
  @moduledoc """
  Defines the default behavior for each Statestore Provider.
  """
  alias Scrivener.Page
  alias Statestores.Schemas.Projection

  @type metadata_key :: String.t()

  @type metadata_value :: String.t()

  @type page :: integer()

  @type page_size :: integer()

  @type page_data :: Page.t()

  @type projection :: Projection.t()

  @type projections :: list(Projection.t())

  @type projection_name :: String.t()

  @type projection_id :: String.t()

  @type revision :: integer()

  @type time_start :: String.t()

  @type time_end :: String.t()

  @callback create_table(projection_name()) :: {:ok, String.t()}

  @callback get_last(projection_name(), projection_id()) :: {:error, any} | {:ok, projection()}

  @callback get_last_by_projection_id(projection_name(), projection_id()) ::
              {:error, any} | {:ok, projection()}

  @callback get_all(projection_name(), page(), page_size()) :: {:error, any} | {:ok, page_data()}

  @callback get_all_by_projection_id(projection_name(), projection_id(), page(), page_size()) ::
              {:error, any} | {:ok, page_data()}

  @callback get_by_interval(
              projection_name(),
              projection_id(),
              time_start(),
              time_end(),
              page(),
              page_size()
            ) :: {:error, any} | {:ok, page_data()}

  @callback get_by_projection_id_and_interval(
              projection_name(),
              projection_id(),
              time_start(),
              time_end(),
              page(),
              page_size()
            ) :: {:error, any} | {:ok, page_data()}

  @callback search_by_metadata(
              projection_name(),
              metadata_key(),
              metadata_value(),
              page(),
              page_size()
            ) ::
              {:error, any} | {:ok, page_data()}

  @callback search_by_projection_id_and_metadata(
              projection_name(),
              projection_id(),
              metadata_key(),
              metadata_value(),
              page(),
              page_size()
            ) :: {:error, any} | {:ok, page_data()}

  @callback save(projection()) :: {:error, any} | {:ok, projection()}

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
