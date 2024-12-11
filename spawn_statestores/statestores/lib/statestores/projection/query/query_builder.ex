defmodule Statestores.Projection.Query.QueryBuilder do
  @moduledoc """
  QueryBuilder module
  """
  def build_query(select_clause, conditions, order_by, binds) do
    select =
      select_clause
      |> Enum.map(&format_select_part/1)
      |> Enum.join(", ")

    where_clauses =
      conditions
      |> Enum.map(fn {key, value} -> format_condition(key, value) end)
      |> Enum.join(" AND ")

    order_by_clause =
      order_by
      |> Enum.map(fn {field, direction} -> "tags->>'#{field}' #{direction}" end)
      |> Enum.join(", ")

    # Gerar query básica
    query = """
    SELECT #{select}
    FROM projections
    WHERE #{where_clauses}
    """

    query = if order_by_clause != "", do: "#{query} ORDER BY #{order_by_clause}", else: query

    # Substituir parâmetros nos binds
    {query, params} =
      Enum.reduce(conditions, {query, []}, fn {_key, value}, {q, params} ->
        case value do
          {:bind, bind_name} ->
            {q, params ++ [{bind_name, Map.get(binds, bind_name)}]}

          _ -> {q, params}
        end
      end)

    {query, params}
  end

  defp format_select_part({:column, field}), do: "tags->>'#{field}' AS #{field}"
  defp format_select_part({:count, _}), do: "COUNT(*)"
  defp format_select_part({:sum, field}), do: "SUM(tags->>'#{field}'::numeric)"
  defp format_select_part({:avg, field}), do: "AVG(tags->>'#{field}'::numeric)"
  defp format_select_part({:max, field}), do: "MAX(tags->>'#{field}'::timestamp)"
  defp format_select_part({:min, field}), do: "MIN(tags->>'#{field}'::timestamp)"

  defp format_condition(key, {:bind, bind_name}), do: "(tags->>'#{key}') = :#{bind_name}"
  defp format_condition(key, {:literal, value}) do
    if String.match?(value, ~r/^true|false$/) do
      "(tags->>'#{key}')::boolean = #{value}"
    else
      "tags->>'#{key}' = '#{value}'"
    end
  end
end