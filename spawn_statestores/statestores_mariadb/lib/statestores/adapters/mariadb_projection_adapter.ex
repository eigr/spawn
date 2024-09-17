defmodule Statestores.Adapters.MariaDBProjectionAdapter do
  @moduledoc """
  Implements the ProjectionBehaviour for MariaDB, with dynamic table name support.
  """
  use Statestores.Adapters.ProjectionBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.MyXQL

  use Scrivener, page_size: 50

  import Ecto.Query

  alias Statestores.Schemas.Projection
  alias Statestores.Schemas.ValueObjectSchema

  @impl true
  def create_table(projection_name) do
    query = """
    CREATE TABLE IF NOT EXISTS #{projection_name} (
      id VARCHAR(255) PRIMARY KEY,
      projection_id VARCHAR(255),
      projection_name VARCHAR(255),
      system VARCHAR(255),
      metadata JSON,
      data_type VARCHAR(255),
      data BLOB,
      inserted_at DATETIME,
      updated_at DATETIME
    );
    """

    Ecto.Adapters.SQL.query(Statestores.Adapters.MariaDBProjectionAdapter, query)
    {:ok, "Table #{projection_name} created or already exists."}
  end

  @impl true
  def get_last(projection_name) do
    query =
      from(p in {projection_name, Projection},
        order_by: [desc: p.updated_at],
        limit: 1
      )

    case __MODULE__.one(query) do
      nil -> {:error, "No record found"}
      projection -> {:ok, projection}
    end
  end

  @impl true
  def get_last_by_projection_id(projection_name, projection_id) do
    query =
      from(p in {projection_name, Projection},
        where: p.projection_id == ^projection_id,
        order_by: [desc: p.updated_at],
        limit: 1
      )

    case __MODULE__.one(query) do
      nil -> {:error, "No record found"}
      projection -> {:ok, projection}
    end
  end

  @impl true
  def get_all(projection_name, page \\ 1, page_size \\ 50) do
    query =
      from(p in {projection_name, Projection},
        order_by: [asc: p.inserted_at]
      )

    case __MODULE__.paginate(query, page: page, page_size: page_size) do
      %Scrivener.Page{} = page_data -> {:ok, page_data}
      _ -> {:error, "No records found"}
    end
  end

  @impl true
  def get_all_by_projection_id(projection_name, projection_id, page \\ 1, page_size \\ 50) do
    query =
      from(p in {projection_name, Projection},
        where: p.projection_id == ^projection_id,
        order_by: [asc: p.inserted_at]
      )

    case __MODULE__.paginate(query, page: page, page_size: page_size) do
      %Scrivener.Page{} = page_data -> {:ok, page_data}
      _ -> {:error, "No records found"}
    end
  end

  @impl true
  def get_by_interval(projection_name, time_start, time_end, page \\ 1, page_size \\ 50) do
    query =
      from(p in {projection_name, Projection},
        where: p.inserted_at >= ^time_start and p.inserted_at <= ^time_end,
        order_by: [asc: p.inserted_at]
      )

    case __MODULE__.paginate(query, page: page, page_size: page_size) do
      %Scrivener.Page{} = page_data -> {:ok, page_data}
      _ -> {:error, "No records found in the given time interval"}
    end
  end

  @impl true
  def get_by_projection_id_and_interval(
        projection_name,
        projection_id,
        time_start,
        time_end,
        page \\ 1,
        page_size \\ 50
      ) do
    query =
      from(p in {projection_name, Projection},
        where:
          p.projection_id == ^projection_id and p.inserted_at >= ^time_start and
            p.inserted_at <= ^time_end,
        order_by: [asc: p.inserted_at]
      )

    case __MODULE__.paginate(query, page: page, page_size: page_size) do
      %Scrivener.Page{} = page_data -> {:ok, page_data}
      _ -> {:error, "No records found in the given time interval"}
    end
  end

  @impl true
  def search_by_metadata(
        projection_name,
        metadata_key,
        metadata_value,
        page \\ 1,
        page_size \\ 50
      ) do
    query =
      from(p in {projection_name, Projection},
        where: fragment("?->>? = ?", p.metadata, ^metadata_key, ^metadata_value),
        order_by: [asc: p.inserted_at]
      )

    case __MODULE__.paginate(query, page: page, page_size: page_size) do
      %Scrivener.Page{} = page_data -> {:ok, page_data}
      _ -> {:error, "No projections found with the given json attribute and projection_id"}
    end
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
    query =
      from(p in {projection_name, Projection},
        where: p.projection_id == ^projection_id,
        where: fragment("?->>? = ?", p.metadata, ^metadata_key, ^metadata_value),
        order_by: [asc: p.inserted_at]
      )

    case __MODULE__.paginate(query, page: page, page_size: page_size) do
      %Scrivener.Page{} = page_data -> {:ok, page_data}
      _ -> {:error, "No projections found with the given json attribute and projection_id"}
    end
  end

  @impl true
  def save(%Projection{} = projection) do
    record = ValueObjectSchema.to_map(projection)
    {:ok, data} = Statestores.Vault.encrypt(record.data)

    # TODO check if this query is correct for all use cases
    query = """
    INSERT INTO #{projection.projection_name}
    (id, projection_id, projection_name, system, metadata, data_type, data, inserted_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
      projection_id = VALUES(projection_id),
      projection_name = VALUES(projection_name),
      system = VALUES(system),
      metadata = VALUES(metadata),
      data_type = VALUES(data_type),
      data = VALUES(data),
      inserted_at = VALUES(inserted_at),
      updated_at = VALUES(updated_at)
    """

    bindings = [
      record.id,
      record.projection_id,
      record.projection_name,
      record.system,
      record.metadata,
      record.data_type,
      data,
      record.inserted_at,
      record.updated_at
    ]

    # Execute the query using Ecto.Adapters.SQL.query/4
    case Ecto.Adapters.SQL.query(__MODULE__, query, bindings) do
      {:ok, _result} -> {:ok, projection}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def default_port, do: "3306"
end
