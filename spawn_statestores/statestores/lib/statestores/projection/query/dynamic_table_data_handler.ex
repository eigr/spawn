defmodule Statestores.Projection.Query.DynamicTableDataHandler do
  @moduledoc """
  Module to dynamically insert, update and query data in a PostgreSQL table based on the definition of a Protobuf module.

  This module supports:
  - Upsert (insert or update based on conflicts).
  - Direct update of records.
  - Query of records with mapping to Protobuf structures.

  ## Usage Example

  iex> DynamicTableDataHandler.upsert(repo, MyProtobufModule, "my_table", %MyProtobufModule{...})
  :ok

  iex> results = DynamicTableDataHandler.query(repo, "SELECT age, metadata FROM example WHERE id = :id", %{id: "value"})
  {:ok, [%{age: 30, metadata: "example data"}]}
  """

  alias Ecto.Adapters.SQL

  @doc """
  Performs a raw query and returns the results.

  ## Parameters

  - `repo`: The Ecto repository module.
  - `query`: The raw SQL query string with named parameters (e.g., :id).
  - `params`: A map of parameter values.

  Returns the result rows as a list of maps.

  ## Examples
    iex> results = DynamicTableDataHandler.query(repo, "SELECT age, metadata FROM example WHERE id = :id", %{id: "value"})
    {:ok, [%{age: 30, metadata: "example data"}]}
  """
  def query(repo, protobuf_module, query, params) do
    case validate_params(query, params) do
      {:error, message} ->
        {:error, message}

      :ok ->
        {query, values} = build_params_for_query(params, query)

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

  defp to_existing_atom_or_new(string) do
    String.to_existing_atom(string)
  rescue
    _e ->
      String.to_atom(string)
  end
end
