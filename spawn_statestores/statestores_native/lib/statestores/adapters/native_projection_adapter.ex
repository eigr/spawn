defmodule Statestores.Adapters.NativeProjectionAdapter do
  @moduledoc """
  Implements the ProjectionBehaviour for Mnesia, with dynamic table name support.
  """
  use Statestores.Adapters.ProjectionBehaviour

  alias Statestores.Schemas.Projection

  import Statestores.Util, only: [normalize_table_name: 1]

  @impl true
  def create_table(nil), do: {:error, "Projection name cannot be nil."}

  def create_table(projection_name) do
    {:ok, "Table #{table_name} created or already exists."}
  end

  @impl true
  def get_last(nil), do: {:error, "No record found"}

  def get_last(projection_name) do
    nil
  end

  @impl true
  def get_last_by_projection_id(nil, _projection_id), do: {:error, "No record found"}
  def get_last_by_projection_id(_projection_name, nil), do: {:error, "No record found"}

  def get_last_by_projection_id(projection_name, projection_id) do
    nil
  end

  @impl true
  def get_all(nil, _page, _page_size), do: {:error, "No records found"}

  def get_all(projection_name, page \\ 1, page_size \\ 50) do
    nil
  end

  @impl true
  def get_all_by_projection_id(nil, _projection_id, _page, _page_size),
    do: {:error, "No records found"}

  def get_all_by_projection_id(_projection_name, nil, _page, _page_size),
    do: {:error, "No records found"}

  def get_all_by_projection_id(projection_name, projection_id, page \\ 1, page_size \\ 50) do
    nil
  end

  @impl true
  def get_by_interval(nil, _time_start, _time_end, _page, _page_size),
    do: {:error, "No records found"}

  def get_by_interval(_projection_name, nil, _time_end, _page, _page_size),
    do: {:error, "No records found"}

  def get_by_interval(_projection_name, _time_start, nil, _page, _page_size),
    do: {:error, "No records found"}

  def get_by_interval(projection_name, time_start, time_end, page \\ 1, page_size \\ 50) do
    nil
  end

  @impl true
  def get_by_projection_id_and_interval(
        nil,
        _projection_id,
        _time_start,
        _time_end,
        _page,
        _page_size
      ),
      do: {:error, "No records found"}

  def get_by_projection_id_and_interval(
        _projection_name,
        nil,
        _time_start,
        _time_end,
        _page,
        _page_size
      ),
      do: {:error, "No records found"}

  def get_by_projection_id_and_interval(
        _projection_name,
        _projection_id,
        nil,
        _time_end,
        _page,
        _page_size
      ),
      do: {:error, "No records found"}

  def get_by_projection_id_and_interval(
        _projection_name,
        _projection_id,
        _time_start,
        nil,
        _page,
        _page_size
      ),
      do: {:error, "No records found"}

  def get_by_projection_id_and_interval(
        projection_name,
        projection_id,
        time_start,
        time_end,
        page \\ 1,
        page_size \\ 50
      ) do
    nil
  end

  @impl true
  def search_by_metadata(
        projection_name,
        metadata_key,
        metadata_value,
        page \\ 1,
        page_size \\ 50
      ) do
    nil
  end

  @impl true
  def search_by_projection_id_and_metadata(
        projection_name,
        projection_id,
        metadata_key,
        metadata_value,
        page \\ 1,
        page_size \\ 50
      ) do
    nil
  end

  @impl true
  def save(%Projection{} = projection) do
    {:ok, projection}
  end

  @impl true
  def default_port, do: "0000"

end
