defmodule Statestores.Projection.Query.TableDataHandler do
  @moduledoc """
  Module to dynamically insert, update and query data in a PostgreSQL table based on the definition of a Protobuf module.

  This module supports:
  - Upsert (insert or update based on conflicts).
  - Direct update of records.
  - Query of records with mapping to Protobuf structures.

  ## Usage Example

  iex> TableDataHandler.upsert(repo, MyProtobufModule, "my_table", %MyProtobufModule{...})
  :OK

  iex> TableDataHandler.update(repo, MyProtobufModule, "my_table", %{filter_key: "value"}, %{update_key: "new_value"})
  :OK

  iex> results = TableDataHandler.query(repo, MyProtobufModule, "my_table", %{filter_key: "value"})
  [%MyProtobufModule{...}]
  """

  alias Ecto.Adapters.SQL

  @doc """
  Performs an upsert (insert or update) of data in the table.

  ## Parameters

  - `repo`: The Ecto repository module.
  - `protobuf_module`: The Elixir module generated from a Protobuf file.
  - `table_name`: Name of the table in the database.
  - `data`: Protobuf structure containing the data to be inserted or updated.

  Returns `:ok` on success.
  """
  def upsert(repo, protobuf_module, table_name, data) do
    descriptor = protobuf_module.descriptor()
    fields = descriptor.field

    primary_key = get_primary_key(fields)

    columns =
      fields
      |> Enum.map(&Macro.underscore(&1.name))

    placeholders = Enum.map(columns, &"$#{Enum.find_index(columns, fn col -> col == &1 end) + 1}")

    updates =
      columns
      |> Enum.reject(&(&1 == primary_key))
      |> Enum.map(&"#{&1} = EXCLUDED.#{&1}")
      |> Enum.join(", ")

    sql = """
    INSERT INTO #{table_name} (#{Enum.join(columns, ", ")})
    VALUES (#{Enum.join(placeholders, ", ")})
    ON CONFLICT (#{primary_key}) DO UPDATE
    SET #{updates}
    """

    values =
      Enum.map(fields, fn field -> Map.get(data, String.to_atom(Macro.underscore(field.name))) end)

    SQL.query!(repo, sql, values)
    :ok
  end

  @doc """
  Performs an update of records in the table.

  ## Parameters

  - `repo`: The Ecto repository module.
  - `protobuf_module`: The Elixir module generated from a Protobuf file.
  - `table_name`: Name of the table in the database.
  - `filters`: Map containing the fields and values ​​to filter the records.
  - `updates`: Map containing the fields and values ​​to update.

  Returns `:ok` on success.
  """
  def update(repo, protobuf_module, table_name, filters, updates) do
    filter_sql =
      Enum.map(filters, fn {key, _value} -> "#{Macro.underscore(key)} = ?" end)
      |> Enum.join(" AND ")

    update_sql =
      Enum.map(updates, fn {key, _value} -> "#{Macro.underscore(key)} = ?" end) |> Enum.join(", ")

    sql = """
    UPDATE #{table_name}
    SET #{update_sql}
    WHERE #{filter_sql}
    """

    values = Enum.concat([Map.values(updates), Map.values(filters)])

    SQL.query!(repo, sql, values)
    :ok
  end

  @doc """
  Performs a query on the table and returns the results mapped to Protobuf structures.

  ## Parameters

  - `repo`: The Ecto repository module.
  - `protobuf_module`: The Elixir module generated from a Protobuf file.
  - `table_name`: Name of the table in the database.
  - `conditions`: List of conditions, where each condition is a tuple `{field, operator, value}` or `{operator, [conditions]}` for logical combinations.

  Example conditions:
  - `[{:field, "=", "value"}, {:field2, ">", 10}]` (with implicit `AND`)
  - `{:or, [{:field, "=", "value"}, {:field2, "<", 5}]}`
  """
  def query(repo, protobuf_module, table_name, conditions) do
    descriptor = protobuf_module.descriptor()
    fields = descriptor.field

    columns = fields |> Enum.map(&Macro.underscore(&1.name))

    {where_clause, values} = build_where_clause(conditions)

    sql = """
    SELECT #{Enum.join(columns, ", ")}
    FROM #{table_name}
    #{where_clause}
    """

    result = SQL.query!(repo, sql, values)

    Enum.map(result.rows, fn row ->
      Enum.zip(columns, row)
      |> Enum.into(%{})
      |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)
      |> protobuf_module.new()
    end)
  end

  defp build_where_clause(conditions) do
    build_conditions(conditions, [])
  end

  defp build_conditions(conditions, acc) when is_list(conditions) do
    Enum.reduce(conditions, {"", acc}, fn
      {:or, sub_conditions}, {clause, acc} ->
        {sub_clause, sub_values} = build_conditions(sub_conditions, acc)
        new_clause = clause <> if clause == "", do: "", else: " OR " <> sub_clause
        {new_clause, sub_values}

      {:and, sub_conditions}, {clause, acc} ->
        {sub_clause, sub_values} = build_conditions(sub_conditions, acc)
        new_clause = clause <> if clause == "", do: "", else: " AND " <> sub_clause
        {new_clause, sub_values}

      {field, op, value}, {clause, acc} ->
        new_clause = clause <> if clause == "", do: "", else: " AND "
        column = Macro.underscore(field)
        placeholder = "?"
        {new_clause <> "#{column} #{op} #{placeholder}", acc ++ [value]}
    end)
  end

  defp get_primary_key(fields) do
    case Enum.find(fields, fn field ->
           Map.get(field.options.__pb_extensions__, {Spawn.Actors.PbExtension, :actor_id}) == true
         end) do
      nil -> "id"
      field -> Macro.underscore(field.name)
    end
  end
end
