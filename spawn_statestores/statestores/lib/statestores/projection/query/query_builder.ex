defmodule Statestores.Projection.Query.QueryBuilder do
  @moduledoc """
  Translates parsed DSL components into SQL, including support for aggregation functions,
  subqueries, and complex WHERE conditions.
  Subqueries are supported in the `WHERE` clause and `SELECT`, and JOINs are used where necessary to combine data.
  """

  @spec build_query(list(), list(), list(), map()) :: {String.t(), list()}
  def build_query(select_clause, conditions, order_by, _binds) do
    select_sql =
      Enum.map(select_clause, fn
        :count_star -> "COUNT(*)"
        {:avg, field} -> "AVG(tags->>'#{field}')::numeric"
        {:min, field} -> "MIN(tags->>'#{field}')::numeric"
        {:max, field} -> "MAX(tags->>'#{field}')::numeric"
        {:rank_over, attr, dir} -> "RANK() OVER (ORDER BY (tags->>'#{inspect(attr)}')::numeric #{String.upcase(to_string(dir))})"
        attr -> "tags->>'#{inspect(attr)}' AS #{inspect(attr)}"
      end)
      |> Enum.join(", ")

    where_sql = build_where_clause(conditions)
    order_by_sql = build_order_by_clause(order_by)

    # A consulta agora garante que o `FROM` será gerado corretamente
    query = "SELECT #{select_sql} FROM projections #{where_sql} #{order_by_sql}"
    {query, []}
  end

  defp build_where_clause([]), do: ""
  defp build_where_clause(conditions) do
    conditions
    |> Enum.map(fn
      {:where, field, operator, value} ->
        build_condition(field, operator, value)

      _ -> ""
    end)
    |> Enum.join(" AND ")
    |> (fn clause -> "WHERE #{clause}" end).()
  end

  defp build_condition(field, operator, value) when is_tuple(value) do
    # Para valores que são subconsultas, vamos tratar isso como uma subquery no WHERE
    subquery = build_subquery(value)
    "#{field} #{operator} (#{subquery})"
  end

  defp build_condition(field, operator, value) do
    "#{field} #{operator} #{value}"
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

    # Gerando a subconsulta com `FROM` e considerando a junção com a tabela principal (projections)
    "SELECT #{select_sql} FROM projections #{where_sql} #{order_by_sql}"
  end

  defp build_order_by_clause([]), do: ""
  defp build_order_by_clause(order_by) do
    order_by
    |> Enum.map(fn {field, direction} ->
      "#{field} #{String.upcase(to_string(direction))}"
    end)
    |> Enum.join(", ")
    |> (fn clause -> "ORDER BY #{clause}" end).()
  end
end
