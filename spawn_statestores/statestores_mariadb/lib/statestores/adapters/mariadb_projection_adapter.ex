defmodule Statestores.Adapters.MariaDBProjectionAdapter do
  @moduledoc """
  Implements the ProjectionBehaviour for MariaDB, with dynamic table name support.
  """
  use Statestores.Adapters.ProjectionBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.MyXQL

  alias Ecto.Adapters.SQL

  @type_map %{
    :TYPE_INT32 => "INT",
    :TYPE_INT64 => "BIGINT",
    :TYPE_STRING => "TEXT",
    :TYPE_BOOL => "BOOLEAN",
    :TYPE_FLOAT => "FLOAT",
    :TYPE_DOUBLE => "DOUBLE",
    :TYPE_BYTES => "LONGBLOB",
    :TYPE_MESSAGE => "JSON",
    :TYPE_ENUM => "TEXT"
  }

  @doc """
  Dynamically creates or updates a table in the PostgreSQL database from a Protobuf module.

  ## Parameters

  - `repo`: The module from the Ecto repository.
  - `protobuf_module`: The Elixir module generated from a Protobuf file.
  - `table_name`: Name of the table to be created or updated in the database.

  ## Example

  iex> create_or_update_table(MyProtobufModule, "my_table")

  """
  @impl true
  def create_or_update_table(protobuf_module, table_name) do
    repo = __MODULE__
    descriptor = protobuf_module.descriptor()
    fields = descriptor.field

    # Create table if it does not exist
    create_table_if_not_exists(repo, table_name, fields)

    # Update table to add missing columns
    update_table_columns(repo, table_name, fields)

    # Add indexes for searchable columns
    create_indexes(repo, table_name, fields)

    :ok
  end

  defp create_table_if_not_exists(repo, table_name, fields) do
    columns_sql =
      fields
      |> Enum.map(&field_to_column_sql/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.join(", ")

    timestamp_columns =
      "created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"

    primary_key_column =
      fields
      |> Enum.find(fn field ->
        options = field.options || %{}

        actor_id_extension =
          options
          |> Map.get(:__pb_extensions__, %{})
          |> Map.get({Spawn.Actors.PbExtension, :actor_id})

        actor_id_extension == true
      end)
      |> case do
        nil ->
          "id BIGINT AUTO_INCREMENT PRIMARY KEY"

        field ->
          column_type =
            if field.label == :LABEL_REPEATED do
              Map.get(@type_map, :TYPE_MESSAGE)
            else
              Map.get(@type_map, field.type)
            end

          length_spec =
            case column_type do
              # Limit index length to the first 255 characters
              "TEXT" -> "(255)"
              # Limit index length to the first 255 bytes
              "BLOB" -> "(255)"
              _ -> ""
            end

          "PRIMARY KEY (#{field.name}#{length_spec})"
      end

    create_table_sql =
      [
        "CREATE TABLE IF NOT EXISTS #{table_name} (",
        columns_sql,
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
        "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ?",
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
      # Determine if the column is TEXT or BLOB
      column_type = Map.get(@type_map, field.type)

      length_spec =
        case column_type do
          # Limit index length to the first 255 characters
          "TEXT" -> "(255)"
          # Limit index length to the first 255 bytes
          "BLOB" -> "(255)"
          _ -> ""
        end

      # Create the index with the length spec if required
      index_sql =
        "CREATE INDEX IF NOT EXISTS idx_#{table_name}_#{validate_column_name(field.name)} " <>
          "ON #{table_name} (#{validate_column_name(field.name)}#{length_spec})"

      SQL.query!(repo, index_sql)
    end)
  end

  defp validate_column_name(name) do
    name
    |> Macro.underscore()
    |> String.replace(~r/[^a-z0-9_]/, "")
  end

  @doc """
  Performs a raw query and returns the results.

  ## Parameters

  - `repo`: The Ecto repository module.
  - `query`: The raw SQL query string with named parameters (e.g., :id).
  - `params`: A map of parameter values.

  Returns the result rows as a list of maps.

  ## Examples
    iex> results = query("SELECT age, metadata FROM example WHERE id = :id", %{id: "value"})
    {:ok, [%{age: 30, metadata: "example data"}]}
  """
  @impl true
  def query(protobuf_module, query, params, opts) do
    repo = __MODULE__

    case validate_params(query, params) do
      {:error, message} ->
        {:error, message}

      {:ok, required_params} ->
        {query, values} = build_params_for_query(params, query, required_params)

        page = opts[:page] || 1
        page_size = opts[:page_size] || 10

        # Append LIMIT and OFFSET dynamically
        offset = (page - 1) * page_size

        {query, values} =
          if has_outer_limit_or_offset?(query) do
            # If already present, don't modify the query
            {query, values}
          else
            query = "#{query} LIMIT ? OFFSET ?"

            values = values ++ [page_size, offset]

            {query, values}
          end

        result = SQL.query!(repo, query, values)

        columns = result.columns

        results =
          Enum.map(result.rows, fn row ->
            map_value = Enum.zip(columns, row) |> Enum.into(%{})

            {:ok, decoded} = from_decoded(protobuf_module, map_value)

            decoded
          end)

        {:ok, results}
    end
  end

  defp from_decoded(module, data) when is_map(data) and is_atom(module) do
    data
    |> decode_fields(module)
    |> Protobuf.JSON.from_decoded(module)
  end

  defp decode_fields(existing_map, module) do
    descriptor = module.descriptor()

    Map.new(existing_map, fn {key, value} ->
      field = Enum.find(descriptor.field, &(&1.name == key))

      cond do
        !field ->
          {key, to_proto_decoded(value)}

        field.type == :TYPE_BOOL ->
          value = value == 1

          {key, to_proto_decoded(value)}

        (field.type == :TYPE_MESSAGE or field.label == :LABEL_REPEATED) and is_bitstring(value) ->
          value = Jason.decode!(value)

          {key, to_proto_decoded(value)}

        true ->
          {key, to_proto_decoded(value)}
      end
    end)
  end

  defp to_proto_decoded(value) when is_boolean(value) do
    value
  end

  defp to_proto_decoded(%NaiveDateTime{} = value) do
    DateTime.from_naive!(value, "Etc/UTC")
    |> to_proto_decoded()
  end

  defp to_proto_decoded(%DateTime{} = value) do
    DateTime.to_iso8601(value)
  end

  defp to_proto_decoded(value) when is_atom(value) do
    Atom.to_string(value)
  end

  defp to_proto_decoded(""), do: nil

  defp to_proto_decoded(value) do
    value
  end

  defp has_outer_limit_or_offset?(query) do
    query
    |> String.split(~r/(\(|\)|\bLIMIT\b|\bOFFSET\b)/i, trim: true, include_captures: true)
    |> Enum.reduce_while(0, fn token, depth ->
      cond do
        token == "(" -> {:cont, depth + 1}
        token == ")" -> {:cont, depth - 1}
        String.match?(token, ~r/\bLIMIT\b|\bOFFSET\b/i) and depth == 0 -> {:halt, true}
        true -> {:cont, depth}
      end
    end)
    |> case do
      true -> true
      _ -> false
    end
  end

  defp build_params_for_query(params, query, required_params) when is_struct(params),
    do: Map.from_struct(params) |> build_params_for_query(query, required_params)

  defp build_params_for_query(params, query, required_params) when is_map(params) do
    Enum.reduce(required_params, {query, []}, fn param, {q, acc} ->
      key = String.to_existing_atom(param)
      value = to_proto_decoded(Map.get(params, key))

      new_query = String.replace(q, ":#{param}", "?")

      {new_query, acc ++ [value]}
    end)
  end

  defp validate_params(query, params) do
    required_params =
      Regex.scan(~r/:("\w+"|\w+)/, query)
      |> List.flatten()
      |> Enum.filter(&String.starts_with?(&1, ":"))
      |> Enum.map(&String.trim_leading(&1, ":"))

    param_keys = params |> Map.keys() |> Enum.map(fn key -> "#{key}" end)

    contains_all_params? = Enum.all?(required_params, fn param -> param in param_keys end)

    if contains_all_params? do
      {:ok, required_params}
    else
      {:error, "Required parameters(s): #{Enum.join(required_params, ", ")}"}
    end
  end

  @doc """
  Performs an upsert (insert or update) of data in the table.

  ## Parameters

  - `repo`: The Ecto repository module.
  - `protobuf_module`: The Elixir module generated from a Protobuf file.
  - `table_name`: Name of the table in the database.
  - `data`: Protobuf structure containing the data to be inserted or updated.

  Returns `:ok` on success.
  """
  @impl true
  def upsert(protobuf_module, table_name, data) do
    repo = __MODULE__

    # Extract the fields from the Protobuf module
    descriptor = protobuf_module.descriptor()
    fields = descriptor.field

    # Map columns and values
    columns = Enum.map(fields, &validate_column_name(&1.name))

    # Construct the placeholders for the values
    placeholders = Enum.map(1..length(columns), fn _ -> "?" end) |> Enum.join(", ")

    # Prepare SET clause for updating values on duplicate key
    update_clause =
      Enum.map(columns, fn col -> "#{col} = VALUES(#{col})" end)
      |> Enum.join(", ")

    # Construct the SQL query for MariaDB
    sql = """
    INSERT INTO #{table_name} (#{Enum.join(columns, ", ")})
    VALUES (#{placeholders})
    ON DUPLICATE KEY UPDATE #{update_clause}
    """

    values =
      Enum.map(fields, fn field ->
        value = Map.get(data, String.to_atom(Macro.underscore(field.name)))

        parse_value = fn
          parse_value, %{__unknown_fields__: _} = struct ->
            Map.from_struct(struct)
            |> Map.delete(:__unknown_fields__)
            |> Map.new(fn {key, value} -> {key, parse_value.(parse_value, value)} end)

          _, value when is_boolean(value) ->
            value

          _, value when is_atom(value) ->
            "#{value}"

          _, value ->
            value
        end

        parse_value.(parse_value, value)
      end)

    # Execute the query
    SQL.query!(repo, sql, values)

    :ok
  end

  @impl true
  def default_port, do: "3306"
end
