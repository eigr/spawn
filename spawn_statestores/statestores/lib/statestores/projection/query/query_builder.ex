defmodule Statestores.Projection.Query.QueryBuilder do
  @moduledoc """
  Translates parsed DSL components into SQL, including support for aggregation functions,
  subqueries, and complex WHERE conditions.
  """

  @spec build_query(list(), list(), list(), map(), list()) :: {String.t(), list()}
  def build_query(select_clause, conditions, order_by, group_by, having_clause \\ []) do
    select_sql =
      select_clause
      |> Enum.filter(&valid_select?/1)
      |> Enum.map(&build_select_clause/1)
      |> Enum.join(", ")

    where_sql = build_where_clause(conditions)
    order_by_sql = build_order_by_clause(order_by)

    group_by_sql =
      case group_by do
        %{} ->
          ""

        [] ->
          ""

        nil ->
          ""

        _ ->
          if valid_group_by?(group_by, select_clause) do
            build_group_by_clause(group_by)
          else
            raise(
              ArgumentError,
              "GROUP BY must be used in conjunction with aggregation functions"
            )
          end
      end

    having_sql = build_having_clause(having_clause)

    query =
      if group_by_sql == "" do
        ["SELECT", select_sql, "FROM projections", where_sql, order_by_sql]
      else
        [
          "SELECT",
          select_sql,
          "FROM projections",
          where_sql,
          group_by_sql,
          having_sql,
          order_by_sql
        ]
      end
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(" ")

    {String.trim(query), []}
  end

  defp build_select_clause(:count_star), do: "COUNT(*)"

  defp build_select_clause({:avg, attr, _opts}), do: "AVG(tags->>'#{attr}')::numeric"

  defp build_select_clause({:min, attr, _opts}), do: "MIN(tags->>'#{attr}')::numeric"

  defp build_select_clause({:max, attr, _opts}), do: "MAX(tags->>'#{attr}')::numeric"

  defp build_select_clause({:sum, attr, _opts}), do: "SUM(tags->>'#{attr}')::numeric"

  defp build_select_clause({:rank_over, attr, dir}),
    do: "RANK() OVER (ORDER BY (tags->>'#{attr}')::numeric #{String.upcase(to_string(dir))})"

  defp build_select_clause({:subquery, subquery, alias_name}),
    do: "(#{subquery}) AS #{alias_name}"

  defp build_select_clause(attr) when is_atom(attr),
    do: "tags->>'#{attr}' AS #{attr}"

  defp build_select_clause(_),
    do: raise(ArgumentError, "Unsupported select clause format")

  defp build_where_clause([]), do: ""

  defp build_where_clause(conditions) do
    conditions
    |> Enum.map(&build_condition/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" AND ")
    |> (&("WHERE " <> &1)).()
  end

  defp build_having_clause([]), do: ""

  defp build_having_clause(conditions) do
    conditions
    |> Enum.map(&build_condition/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" AND ")
    |> (&("HAVING " <> &1)).()
  end

  defp build_condition({:where, field, operator, value}) when is_tuple(value) do
    subquery = build_subquery(value)
    "#{field} #{operator} (#{subquery})"
  end

  defp build_condition({:where, field, operator, value}) do
    formatted_value =
      if is_binary(value), do: "'#{String.trim(value, "'")}'", else: value

    "#{field} #{operator} #{formatted_value}"
  end

  defp build_condition({:having, field, operator, value}) when is_tuple(value) do
    subquery = build_subquery(value)
    "#{field} #{operator} (#{subquery})"
  end

  defp build_condition({:having, field, operator, value}) do
    formatted_value =
      if is_binary(value), do: "'#{String.trim(value, "'")}'", else: value

    "#{field} #{operator} #{formatted_value}"
  end

  defp build_subquery({:select, select_clause, where_clause, order_by_clause}) do
    select_sql =
      select_clause
      |> Enum.map(&build_select_clause/1)
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

  defp build_group_by_clause([]), do: ""

  defp build_group_by_clause(group_by) do
    group_by
    |> Enum.map(&to_string/1)
    |> Enum.join(", ")
    |> (&("GROUP BY " <> &1)).()
  end

  defp valid_select?(:count_star), do: true
  defp valid_select?({:avg, _attr, _opts}), do: true
  defp valid_select?({:min, _attr, _opts}), do: true
  defp valid_select?({:max, _attr, _opts}), do: true
  defp valid_select?({:sum, _attr, _opts}), do: true
  defp valid_select?({:rank_over, _attr, _dir}), do: true
  defp valid_select?({:subquery, _query, _alias_name}), do: true
  defp valid_select?(attr) when is_atom(attr), do: true
  defp valid_select?(_), do: false

  defp valid_group_by?(_group_by, select_clause) do
    Enum.any?(select_clause, &aggregation_function?/1)
  end

  defp aggregation_function?(:count_star), do: true
  defp aggregation_function?({:avg, _, _}), do: true
  defp aggregation_function?({:min, _, _}), do: true
  defp aggregation_function?({:max, _, _}), do: true
  defp aggregation_function?({:sum, _, _}), do: true
  defp aggregation_function?(_), do: false
end
