defmodule Statestores.Projection.DynamicTableCreator do
  @moduledoc """
  Module to dynamically create or update tables in the PostgreSQL database based on the Protobuf message structure.

  This module parses the definition of a Protobuf module, extracting information about the fields and generating SQL commands to create or alter the corresponding table in the database. It also supports creating indexes for columns marked as searchable and automatically adding timestamp columns (`created_at` and `updated_at`).

  ## Features

  - Generation and updates of PostgreSQL tables based on the definition of fields in a Protobuf.
  - Mapping of Protobuf data types to PostgreSQL data types.
  - Creation of indexes on columns configured as `searchable`.
  - Support for nested Protobuf fields (of type `TYPE_MESSAGE`), stored as `JSONB`.

  ## Usage Example
      
      ```elixir
      iex> DynamicTableCreator.create_or_update_table(MyApp.Repo, MyProtobufModule, "my_table")
      ```

  """

  alias Ecto.Adapters.SQL
  alias Ecto.Migration

  @type_map %{
    :TYPE_INT32 => "INTEGER",
    :TYPE_INT64 => "BIGINT",
    :TYPE_STRING => "TEXT",
    :TYPE_BOOL => "BOOLEAN",
    :TYPE_FLOAT => "REAL",
    :TYPE_DOUBLE => "DOUBLE PRECISION",
    :TYPE_BYTES => "BYTEA",
    :TYPE_MESSAGE => "JSONB",
    :TYPE_ENUM => "TEXT"
  }

  @doc """
  Dynamically creates or updates a table in the PostgreSQL database from a Protobuf module.

  ## Parameters

  - `repo`: The module from the Ecto repository.
  - `protobuf_module`: The Elixir module generated from a Protobuf file.
  - `table_name`: Name of the table to be created or updated in the database.

  ## Example

  iex> DynamicTableCreator.create_or_update_table(MyApp.Repo, MyProtobufModule, "my_table")

  """
  @spec create_or_update_table(Ecto.Repo.t(), module(), String.t()) :: :ok
  def create_or_update_table(repo, protobuf_module, table_name) do
    descriptor = protobuf_module.descriptor()
    fields = descriptor.field

    {:ok, _} =
      repo.transaction(fn ->
        # Create table if it does not exist
        create_table_if_not_exists(repo, table_name, fields)

        # Update table to add missing columns
        update_table_columns(repo, table_name, fields)

        # Add indexes for searchable columns
        create_indexes(repo, table_name, fields)
      end)

    :ok
  end

  defp create_table_if_not_exists(repo, table_name, fields) do
    columns_sql =
      fields
      |> Enum.map(&field_to_column_sql/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.join(", ")

    timestamp_columns =
      "created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP"

    type_url_column = "type_url TEXT NOT NULL"

    primary_key_column =
      fields
      |> Enum.find(fn field ->
        Map.get(field.options.__pb_extensions__, {Spawn.Actors.PbExtension, :actor_id}) == true
      end)
      |> case do
        nil -> "id SERIAL PRIMARY KEY"
        field -> "PRIMARY KEY (#{Macro.underscore(field.name)})"
      end

    create_table_sql =
      [
        "CREATE TABLE IF NOT EXISTS #{table_name} (",
        columns_sql,
        ", #{type_url_column}",
        ", #{timestamp_columns}",
        ", #{primary_key_column}",
        ")"
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")

    SQL.query!(repo, create_table_sql)
  end

  defp update_table_columns(repo, table_name, fields) do
    existing_columns =
      SQL.query!(
        repo,
        "SELECT column_name FROM information_schema.columns WHERE table_name = $1",
        [table_name]
      )
      |> Map.get(:rows)
      |> List.flatten()

    fields
    |> Enum.reject(fn field -> validate_column_name(field.name) in existing_columns end)
    |> Enum.each(fn field ->
      column_sql = field_to_column_sql(field)
      alter_table_sql = "ALTER TABLE #{table_name} ADD COLUMN #{column_sql}"
      SQL.query!(repo, alter_table_sql)
    end)
  end

  defp field_to_column_sql(%{name: "created_at"}), do: nil
  defp field_to_column_sql(%{name: "updated_at"}), do: nil
  defp field_to_column_sql(%{name: "type_url"}), do: nil

  defp field_to_column_sql(%{name: name, type: type} = field) do
    column_name = validate_column_name(name)
    nullable = if field.label == :LABEL_OPTIONAL, do: "NULL", else: "NOT NULL"

    column_type =
      if field.label == :LABEL_REPEATED do
        Map.get(@type_map, :TYPE_MESSAGE)
      else
        Map.get(@type_map, type)
      end

    "#{column_name} #{column_type} #{nullable}"
  end

  defp create_indexes(repo, table_name, fields) do
    fields
    |> Enum.reject(fn field -> is_nil(field.options) end)
    |> Enum.filter(fn field ->
      Map.get(field.options.__pb_extensions__, {Spawn.Actors.PbExtension, :searchable}) == true
    end)
    |> Enum.each(fn field ->
      index_sql =
        "CREATE INDEX IF NOT EXISTS idx_#{table_name}_#{validate_column_name(field.name)} ON #{table_name} (#{validate_column_name(field.name)})"

      SQL.query!(repo, index_sql)
    end)
  end

  defp validate_column_name(name) do
    name
    |> Macro.underscore()
    |> String.replace(~r/[^a-z0-9_]/, "")
  end
end