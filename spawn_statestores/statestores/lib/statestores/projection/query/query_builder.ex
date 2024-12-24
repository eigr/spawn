defmodule Statestores.Projection.Query.QueryBuilder do
  @moduledoc """
  Translates parsed DSL components into SQL, including support for aggregation functions,
  subqueries, and complex WHERE conditions.
  """

  @spec build_query(list(), list(), list(), map()) :: {String.t(), list()}
  def build_query(select_clause, conditions, order_by, _binds) do
    select_sql =
      select_clause
      |> IO.inspect(label: "select_clause")
      |> Enum.filter(&valid_select?/1)
      |> Enum.map(fn
        :count_star -> 
          "COUNT(*)"

        {:avg, attr, _opts} -> 
          "AVG(tags->>'#{attr}')::numeric"

        {:min, attr} -> 
          "MIN(tags->>'#{attr}')::numeric"
        
        {:min, attr, _opts} -> 
          "MIN(tags->>'#{attr}')::numeric"

        {:max, attr} -> 
          "MAX(tags->>'#{attr}')::numeric"

        {:max, attr, _opts} -> 
          "MAX(tags->>'#{attr}')::numeric"

        {:sum, attr} -> 
          "SUM(tags->>'#{attr}')::numeric"

        {:sum, attr, _opts} -> 
          "SUM(tags->>'#{attr}')::numeric"

        {:rank_over, attr, dir} ->
          "RANK() OVER (ORDER BY (tags->>'#{attr}')::numeric #{String.upcase(to_string(dir))})"

        attr when is_atom(attr) -> 
          "tags->>'#{attr}' AS #{attr}"

        _ -> 
          raise ArgumentError, "Unsupported select clause format"
      end)
      |> Enum.join(", ")

    where_sql = build_where_clause(conditions)
    order_by_sql = build_order_by_clause(order_by)

    query =
      ["SELECT", select_sql, "FROM projections", where_sql, order_by_sql]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(" ")

    {String.trim(query), []}
  end

  defp build_where_clause([]), do: ""
  defp build_where_clause(conditions) do
    conditions
    |> Enum.map(fn
      {:where, field, operator, value} ->
        build_condition(field, operator, value)

      _ -> ""
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" AND ")
    |> (&("WHERE " <> &1)).()
  end

  defp build_condition(field, operator, value) when is_tuple(value) do
    subquery = build_subquery(value)
    "#{field} #{operator} (#{subquery})"
  end

  defp build_condition(field, operator, value) do
    formatted_value = 
      case value do
        ^value when is_binary(value) -> "'#{String.trim(value, "'")}'"
        _ -> value
      end
  
    "#{field} #{operator} #{formatted_value}"
  end

  defp build_subquery({:select, select_clause, where_clause, order_by_clause}) do
    select_sql =
      Enum.map(select_clause, fn
        :count_star -> "COUNT(*)"
        {:avg, field} -> "AVG(tags->>'#{field}')::numeric"
        {:min, field} -> "MIN(tags->>'#{field}')::numeric"
        {:max, field} -> "MAX(tags->>'#{field}')::numeric"
        {:rank_over, attr, dir} -> "RANK() OVER (ORDER BY (tags->>'#{attr}')::numeric #{String.upcase(to_string(dir))})"
        attr -> "tags->>'#{attr}' AS #{attr}"
      end)
      |> Enum.join(", ")
  
    where_sql = build_where_clause(where_clause)
    order_by_sql = build_order_by_clause(order_by_clause)
  
    ["SELECT", select_sql, "FROM projections", where_sql, order_by_sql]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
    |> String.trim()
  end
  

  defp build_order_by_clause([]), do: ""
  defp build_order_by_clause(order_by) do
    order_by
    |> Enum.map(fn {field, direction} ->
      "#{field} #{String.upcase(to_string(direction))}"
    end)
    |> Enum.join(", ")
    |> (&("ORDER BY " <> &1)).()
  end

  defp valid_select?(:count_star), do: true
  defp valid_select?({:avg, _attr, _opts}), do: true
  defp valid_select?({:min, _attr}), do: true
  defp valid_select?({:min, _attr, _opts}), do: true
  defp valid_select?({:max, _attr}), do: true
  defp valid_select?({:max, _attr, _opts}), do: true
  defp valid_select?({:sum, _attr}), do: true
  defp valid_select?({:sum, _attr, _opts}), do: true
  defp valid_select?({:rank_over, _attr, _dir}), do: true
  defp valid_select?(attr) when is_atom(attr), do: true
  defp valid_select?(_), do: false

end
