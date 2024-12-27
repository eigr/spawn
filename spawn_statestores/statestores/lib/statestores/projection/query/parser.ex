defmodule Statestores.Projection.Query.Parser do
  import NimbleParsec

  # Basic definitions
  whitespace = ascii_string([?\s, ?\t], min: 1)
  word = ascii_string([?a..?z, ?A..?Z, ?_, ?0..?9], min: 1)
  number = integer(min: 1)

  # Operators
  operator =
    choice([string(">="), string("<="), string("!="), string(">"), string("<"), string("=")])

  # Aggregate functions
  aggregate_func =
    choice([string("sum"), string("avg"), string("min"), string("max"), string("count")])

  # SELECT
  select_field =
    choice([
      aggregate_func
      |> ignore(string("("))
      |> concat(word |> tag(:field))
      |> ignore(string(")"))
      |> optional(
        ignore(whitespace)
        |> ignore(string("as"))
        |> ignore(whitespace)
        |> concat(word |> tag(:alias))
      )
      |> tag(:func_field),
      word
      |> tag(:field)
      |> optional(
        ignore(whitespace)
        |> ignore(string("as"))
        |> ignore(whitespace)
        |> concat(word |> tag(:alias))
      )
    ])

  select_clause =
    ignore(string("select"))
    |> ignore(whitespace)
    |> concat(select_field)
    |> repeat(ignore(string(",") |> ignore(whitespace)) |> concat(select_field))
    |> reduce({__MODULE__, :build_select, []})

  # WHERE
  condition =
    word
    |> tag(:field)
    |> ignore(whitespace)
    |> concat(operator |> tag(:operator))
    |> ignore(whitespace)
    |> concat(choice([number, word]) |> tag(:value))

  conditions =
    condition
    |> repeat(
      ignore(whitespace)
      |> choice([string("and"), string("or")])
      |> ignore(whitespace)
      |> concat(condition)
    )

  where_clause =
    ignore(string("where"))
    |> ignore(whitespace)
    |> concat(conditions)
    |> reduce({__MODULE__, :build_where, []})

  # HAVING
  having_clause =
    ignore(string("having"))
    |> ignore(whitespace)
    |> concat(
      choice([
        # Aggregate function with operator and value
        aggregate_func
        |> tag(:func)
        |> ignore(string("("))
        |> concat(word |> tag(:field))
        |> ignore(string(")"))
        |> ignore(whitespace)
        |> concat(operator |> tag(:operator))
        |> ignore(whitespace)
        |> concat(choice([number, word]) |> tag(:value))
        |> reduce({__MODULE__, :build_having_condition, []}),

        # Simple field with operator and value
        word
        |> tag(:field)
        |> ignore(whitespace)
        |> concat(operator |> tag(:operator))
        |> ignore(whitespace)
        |> concat(choice([number, word]) |> tag(:value))
        |> reduce({__MODULE__, :build_having_condition, []})
      ])
    )
    |> repeat(
      ignore(whitespace)
      |> choice([string("and"), string("or")])
      |> ignore(whitespace)
      |> concat(
        choice([
          # Repeat the same logic for subsequent conditions
          aggregate_func
          |> tag(:func)
          |> ignore(string("("))
          |> concat(word |> tag(:field))
          |> ignore(string(")"))
          |> ignore(whitespace)
          |> concat(operator |> tag(:operator))
          |> ignore(whitespace)
          |> concat(choice([number, word]) |> tag(:value))
          |> reduce({__MODULE__, :build_having_condition, []}),
          word
          |> tag(:field)
          |> ignore(whitespace)
          |> concat(operator |> tag(:operator))
          |> ignore(whitespace)
          |> concat(choice([number, word]) |> tag(:value))
          |> reduce({__MODULE__, :build_having_condition, []})
        ])
      )
    )
    |> reduce({__MODULE__, :build_having, []})

  # GROUP BY
  group_by_clause =
    string("group by")
    |> ignore(whitespace)
    |> concat(word)
    |> repeat(ignore(string(",") |> ignore(whitespace)) |> concat(word))
    |> reduce({__MODULE__, :build_group_by, []})

  # ORDER BY
  order_by_clause =
    ignore(string("order by"))
    |> ignore(whitespace)
    |> concat(word |> tag(:field))
    |> optional(
      ignore(whitespace)
      |> concat(choice([string("asc"), string("desc")]) |> tag(:direction))
    )
    |> repeat(
      ignore(string(",") |> ignore(whitespace))
      |> concat(word |> tag(:field))
      |> optional(
        ignore(whitespace)
        |> concat(choice([string("asc"), string("desc")]) |> tag(:direction))
      )
    )
    |> reduce({__MODULE__, :build_order_by, []})

  # Parser definition
  query_parser =
    select_clause
    |> optional(ignore(whitespace) |> concat(where_clause))
    |> optional(ignore(whitespace) |> concat(group_by_clause))
    |> optional(ignore(whitespace) |> concat(having_clause))
    |> optional(ignore(whitespace) |> concat(order_by_clause))

  defparsec(:parse_query, query_parser)

  @doc """
  Parse a DSL query and return a tuple with the parsed query parts.
  e.g.:
  ```
  iex> Parser.parse("select sum(points) as total, name where age > 30 and salary <= 5000 group by department having count(employees) > 10 order by total desc")
  {:ok, [
    [{:sum, :points, :total}, {nil, :name, nil}],
    [{:where, :age, ">", 30}, {:where, :salary, "<=", 5000}],
    [:department],
    [{:having, :employees, ">", 10}],
    [{:total, :desc}]
  ], "", "", "", ""}
  ```
  """
  @spec parse(String.t()) :: {:ok, [select :: list(), where :: list(), group_by :: list(), having :: list(), order_by :: list()]} | {:error, String.t()}
  def parse(dsl) do
    case parse_query(dsl) do
      {:ok, [select, where, group_by, having, order_by], "", _, _, _} ->
        {select, where || [], group_by || [], having || [], order_by || []}

      {:ok, [select], "", _, _, _} ->
        {select, [], [], [], []}

      {:error, reason, _, _, _, _} ->
        {:error, reason}
    end
  end

  def build_select(list) do
    Enum.map(list, fn
      {:func_field, [func, field, alias_name]} ->
        {:field, fields} = field
        {:alias, alias_names} = alias_name

        {String.to_atom(parse_value(func)), String.to_atom(parse_value(fields)),
         parse_value(alias_names) && String.to_atom(parse_value(alias_names))}

      {:field, [field, alias_name]} ->
        {nil, String.to_atom(parse_value(field)),
         alias_name && String.to_atom(List.to_string(alias_name))}

      {:field, fields} ->
        {nil, String.to_atom(parse_value(fields)), nil}
    end)
  end

  def build_where(conditions), do: build_conditions(conditions)

  def build_having(conditions) do
    Enum.map(conditions, fn
      {:and, _} -> :and
      {:or, _} -> :or
      condition -> condition
    end)
  end

  def build_having_condition([
        {:func, func},
        {:field, field},
        {:operator, operator},
        {:value, value}
      ]) do
    %{
      func: String.to_atom(parse_value(func)),
      field: String.to_atom(parse_value(field)),
      operator: String.to_atom(parse_value(operator)),
      value: parse_value(value)
    }
  end

  def build_having_condition([{:field, field}, {:operator, operator}, {:value, value}]) do
    %{
      field: String.to_atom(parse_value(field)),
      operator: String.to_atom(parse_value(operator)),
      value: parse_value(value)
    }
  end

  def build_conditions(conditions) do
    Enum.reduce(conditions, {[], nil}, fn
      {:field, [field]}, {acc, current_condition} ->
        #Adds the field to the current condition
        {acc, Map.put(current_condition || %{}, :field, String.to_atom(field))}

      {:operator, [operator]}, {acc, current_condition} ->
        # Add operator to current condition
        {acc, Map.put(current_condition || %{}, :operator, String.to_atom(operator))}

      {:value, [value]}, {acc, current_condition} ->
        # Adds the value to the current condition and ends
        condition = Map.put(current_condition || %{}, :value, value)
        {[condition | acc], nil}

      "and", {acc, _current_condition} ->
        # Adds the logical operator "and" as a separator
        {[{:and} | acc], nil}

      "or", {acc, _current_condition} ->
        # Adds the logical operator "or" as a separator
        {[{:or} | acc], nil}

      # Ignore any unexpected input
      _, acc ->
        acc
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  def build_group_by(fields), do: Enum.map(fields, &String.to_atom/1)

  def build_order_by(order_by_clauses) when is_list(order_by_clauses) do
    Enum.map(order_by_clauses, fn
      {:field, [field_name]} when is_binary(field_name) ->
        {String.to_atom(field_name), :asc}

      {:direction, [direction]} when direction in ["asc", "desc"] ->
        {nil, String.to_atom(direction)}

      clause when is_list(clause) ->
        field = Keyword.get(clause, :field, ["unknown"])
        direction = Keyword.get(clause, :direction, ["asc"])

        {String.to_atom(hd(field)), String.to_atom(hd(direction))}

      _ ->
        raise ArgumentError, "Invalid order by clause"
    end)
  end

  def build_order_by(order_by_clause) when is_map(order_by_clause) do
    build_order_by([order_by_clause])
  end

  defp parse_value(value) when is_list(value), do: List.to_string(value)
  defp parse_value(value), do: value
end
