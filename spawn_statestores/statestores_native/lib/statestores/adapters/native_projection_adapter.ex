defmodule Statestores.Adapters.NativeProjectionAdapter do
  @moduledoc """
  Implements the ProjectionBehaviour for Mnesia, with dynamic table name support.
  """
  use Statestores.Adapters.ProjectionBehaviour
  use GenServer

  alias Statestores.Schemas.Projection

  import Statestores.Util, only: [normalize_table_name: 1]

  @impl true
  def create_or_update_table(_projection_type, _table_name) do
    raise "Projections are not supported using native adapter"
  end

  @impl true
  def upsert(_projection_type, _table_name, _data) do
    raise "Projections are not supported using native adapter"
  end

  @impl true
  def query(_projection_type, _query, _params, _opts) do
    raise "Projections are not supported using native adapter"
  end

  @impl true
  def default_port, do: "0000"

  def child_spec(_),
    do: %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }

  def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl GenServer
  def init(_), do: {:ok, nil}
end