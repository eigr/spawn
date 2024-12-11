defmodule Statestores.Projection.Query.Parser do
  @moduledoc """
  Query Parser module
  """

  def parse(dsl) do
    [select_part, rest] = String.split(dsl, " where ", parts: 2)

    select_clause = parse_select(select_part)

    {where_part, order_by_part} =
      case String.split(rest || "", " order by ", parts: 2) do
        [where] -> {where, nil}
        [where, order] -> {where, order}
        _ -> {nil, nil}
      end

    conditions =
      if where_part do
        where_part
        |> String.split(" and ")
        |> Enum.map(&parse_condition/1)
      else
        []
      end

    order_by =
      if order_by_part do
        order_by_part
        |> String.split(", ")
        |> Enum.map(&parse_order/1)
      else
        []
      end

    {select_clause, conditions, order_by}
  end

  defp parse_select(select_part) do
    select_part
    |> String.replace("select ", "")
    |> String.split(", ")
    |> Enum.map(&parse_column_or_function/1)
  end

  defp parse_column_or_function(column) do
    case String.split(column, "(") do
      [func, args] ->
        {String.to_atom(func), String.trim_trailing(args, ")")}
      _ ->
        {:column, column}
    end
  end

  defp parse_condition(condition) do
    cond do
      String.contains?(condition, " = ") ->
        [key, value] = String.split(condition, " = ")
        {key, parse_value(value)}

      true ->
        raise ArgumentError, "Invalid condition format: #{condition}"
    end
  end

  defp parse_value(value) do
    if String.starts_with?(value, ":") do
      {:bind, String.trim_leading(value, ":")}
    else
      {:literal, value}
    end
  end

  defp parse_order(order) do
    [field, direction] = String.split(order, " ")
    {field, direction}
  end
end