defmodule Statestores.Projection.Query.Parser do
  @moduledoc """
  Parser for the custom DSL with subqueries treated as expressions.

  ## Examples

      iex> Parser.parse("select player_id, (select sum(points) where level = 'expert') as total_points")
      {[:player_id, {:subquery, :sum, :points, %{level: 'expert'}}], [], []}
  """

  @spec parse(String.t()) :: {list(), list(), list()}
  def parse(dsl) do
    {select_clause, rest} = parse_select_clause(dsl)
    {select_clause, [], parse_order_by(rest)}
  end

  defp parse_select_clause(dsl) do
    [_, select, rest] = Regex.run(~r/^select (.+?) (where|$)/, dsl)

    select_clause =
      select
      |> String.split(", ")
      |> Enum.map(&parse_select_item/1)

    {select_clause, rest}
  end

  defp parse_select_item("select " <> rest) do
    # The subquery is treated as an expression in the SELECT
    {:subquery, parse_subquery(rest)}
  end

  defp parse_select_item(attr), do: String.to_atom(attr)

  defp parse_subquery(dsl) do
    # Extract the expression from the subquery
    [_, func, field, condition] = Regex.run(~r/^(sum|avg|min|max|count)\((.*?)\) where (.*)/, dsl)
    {String.to_atom(func), String.to_atom(field), parse_condition(condition)}
  end

  defp parse_condition(condition) do
    # Handles the filter condition (e.g. `level = 'expert'`)
    Enum.into(String.split(condition, " and "), %{}, fn pair ->
      [key, value] = String.split(pair, "=")
      {String.to_atom(key), String.trim(value, "'")}
    end)
  end

  defp parse_order_by(rest) do
    case Regex.run(~r/order by (.+)/, rest) do
      [_, clause] ->
        clause
        |> String.split(", ")
        |> Enum.map(fn item ->
          [attr, dir] = String.split(item, " ")
          {String.to_atom(attr), String.to_atom(dir)}
        end)

      _ ->
        []
    end
  end
end
