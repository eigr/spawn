defmodule Statestores.Adapters.PostgresProjectionAdapter do
  @moduledoc """
  Implements the ProjectionBehaviour for Postgres, with dynamic table name support.
  """
  use Statestores.Adapters.ProjectionBehaviour

  use Ecto.Repo,
    otp_app: :spawn_statestores,
    adapter: Ecto.Adapters.Postgres

  alias Ecto.Adapters.SQL

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

  iex> create_or_update_table(MyProtobufModule, "my_table")

  """
  @impl true
  def create_or_update_table(protobuf_module, table_name) do
    repo = __MODULE__
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
        nil -> "id SERIAL PRIMARY KEY"
        field -> "PRIMARY KEY (#{Macro.underscore(field.name)})"
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

      :ok ->
        {query, values} = build_params_for_query(params, query)

        page = opts[:page] || 1
        page_size = opts[:page_size] || 10
        # Append LIMIT and OFFSET dynamically
        offset = (page - 1) * page_size

        {query, values} =
          if has_outer_limit_or_offset?(query) do
            # If already present, don't modify the query
            {query, values}
          else
            query = """
            #{query}
            LIMIT $#{length(values) + 1}
            OFFSET $#{length(values) + 2}
            """

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

  defp build_params_for_query(params, query) when is_struct(params),
    do: Map.from_struct(params) |> build_params_for_query(query)

  defp build_params_for_query(params, query) when is_map(params) do
    Enum.reduce(params, {query, []}, fn {key, value}, {q, acc} ->
      if String.contains?(q, ":#{key}") do
        {String.replace(q, ":#{key}", "$#{length(acc) + 1}"), acc ++ [value]}
      else
        {q, acc}
      end
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
      :ok
    else
      {:error, "Required parameters(s): #{Enum.join(required_params, ", ")}"}
    end
  end

  defp from_decoded(module, data) when is_map(data) and is_atom(module) do
    data
    |> to_proto_decoded()
    |> Protobuf.JSON.from_decoded(module)
  end

  defp to_proto_decoded({k, v}) when is_atom(k) do
    {Atom.to_string(k), to_proto_decoded(v)}
  end

  defp to_proto_decoded({k, v}) do
    {k, to_proto_decoded(v)}
  end

  defp to_proto_decoded(value) when is_list(value) do
    Enum.map(value, &to_proto_decoded/1)
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

  defp to_proto_decoded(existing_map) when is_map(existing_map) do
    Map.new(existing_map, &to_proto_decoded/1)
  end

  defp to_proto_decoded(""), do: nil

  defp to_proto_decoded(value) do
    value
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

    SQL.query!(repo, sql, values)

    :ok
  end

  defp get_primary_key(fields) do
    case Enum.find(fields, fn field ->
           options = field.options || %{}

           actor_id_extension =
             options
             |> Map.get(:__pb_extensions__, %{})
             |> Map.get({Spawn.Actors.PbExtension, :actor_id})

           actor_id_extension == true
         end) do
      nil -> "id"
      field -> Macro.underscore(field.name)
    end
  end

  @impl true
  def default_port, do: "5432"
end
