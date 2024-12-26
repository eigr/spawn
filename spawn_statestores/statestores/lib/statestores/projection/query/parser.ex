defmodule Statestores.Projection.Query.Parser do
  import NimbleParsec

  # Definições básicas
  whitespace = ascii_string([?\s, ?\t], min: 1)
  word = ascii_string([?a..?z, ?A..?Z, ?_, ?0..?9], min: 1)
  number = integer(min: 1)
  operator = choice([string(">"), string("<"), string(">="), string("<="), string("="), string("!=")])

  # SELECT
  select_clause =
    ignore(string("select"))
    |> ignore(whitespace)
    |> concat(
      choice([
          choice([
            # Função com alias
            string("sum"),
            string("avg"),
            string("min"),
            string("max"),
            string("count")])
            |> tag(:func)
            |> ignore(string("("))
            |> concat(word |> tag(:field))
            |> ignore(string(")"))
            |> optional(ignore(whitespace)
            |> ignore(string("as")) 
            |> ignore(whitespace) 
            |> concat(word |> tag(:alias))),
            # Campo simples
            word 
            |> tag(:field) 
            |> optional(ignore(whitespace) 
            |> ignore(string("as"))
            |> ignore(whitespace) 
            |> concat(word |> tag(:alias)))
      ])
    )
    |> reduce({__MODULE__, :build_select, []})

  # WHERE
  where_clause =
    string("where")
    |> ignore(whitespace)
    |> concat(
      repeat(
        word
        |> tag(:field)
        |> ignore(whitespace)
        |> concat(operator |> tag(:operator))
        |> ignore(whitespace)
        |> concat(choice([number, word]) |> tag(:value))
        |> optional(
          ignore(whitespace)
          |> string("and")
          |> ignore(whitespace)
        )
      )
    )
    |> reduce({__MODULE__, :build_where, []})

  # GROUP BY
  group_by_clause =
    string("group by")
    |> ignore(whitespace)
    |> concat(word)
    |> repeat(ignore(string(", ")) |> concat(word))
    |> reduce({__MODULE__, :build_group_by, []})

  # HAVING
  having_clause =
    ignore(string("having"))
    |> ignore(whitespace)
    |> concat(
        choice([
            choice([
              # Função com alias
              string("sum"),
              string("avg"),
              string("min"),
              string("max"),
              string("count")
            ])
            |> tag(:func)
            |> ignore(string("("))
            |> concat(word |> tag(:field))
            |> ignore(string(")")),
            # Campo simples
            word 
            |> tag(:field) 
            |> optional(ignore(whitespace) 
            |> concat(operator |> tag(:operator)) 
            |> ignore(whitespace) 
            |> choice([number, word])
            |> tag(:value) 
        )
      ])
    )
    |> reduce({__MODULE__, :build_having, []})

  # ORDER BY
  order_by_clause =
    string("order by")
    |> ignore(whitespace)
    |> concat(word |> tag(:field))
    |> ignore(whitespace)
    |> concat(choice([string("asc"), string("desc")]) |> tag(:direction))
    |> reduce({__MODULE__, :build_order_by, []})

  # Combinação final
  query_parser =
    select_clause
    |> optional(ignore(whitespace) |> concat(where_clause))
    |> optional(ignore(whitespace) |> concat(group_by_clause))
    |> optional(ignore(whitespace) |> concat(having_clause))
    |> optional(ignore(whitespace) |> concat(order_by_clause))

  defparsec :parse_query, query_parser

  # Funções auxiliares
  def parse(dsl) do
    case parse_query(dsl) do
      {:ok, [select, where, group_by, having, order_by], "", _, _, _} ->
        {select, where || [], group_by || [], having || [], order_by || []}

      {:ok, [select, group_by, having, order_by], "", _, _, _} ->
        {select, [], group_by || [], having || [], order_by || []}

      {:ok, [select, group_by, order_by], "", _, _, _} ->
        {select, [], group_by || [], [], order_by || []}

      {:ok, [select], "", _, _, _} ->
        {select, [], [], [], []}

      {:error, reason, _, _, _, _} ->
        {:error, reason}
    end
  end

  def build_select(list) do
    func = Keyword.get(list, :func, [])
    field = Keyword.get(list, :field, [])
    alias_name = Keyword.get(list, :alias, [])

    func_atom = if func != [], do: String.to_atom(List.to_string(func)), else: nil
    field_atom = String.to_atom(List.to_string(field))
    alias_atom = if alias_name != [], do: String.to_atom(List.to_string(alias_name)), else: nil

    {func_atom, field_atom, alias_atom}
  end

  def build_where(conditions) do
    IO.inspect(conditions, label: "conditions")
    Enum.map(conditions, fn %{field: field, operator: operator, value: value} ->
      {
        String.to_atom(List.to_string(field)),
        String.to_atom(List.to_string(operator)),
        parse_value(value)
      }
    end)
  end

  def build_group_by(fields) do
    Enum.map(fields, &String.to_atom/1)
  end

  def build_having(list) do
    field = Keyword.get(list, :field, [])
    operator = Keyword.get(list, :operator, [])
    value = Keyword.get(list, :value, [])

    {
      String.to_atom(List.to_string(field)),
      String.to_atom(List.to_string(operator)),
      parse_value(value)
    }
  end

  def build_order_by(list) do
    field = Keyword.get(list, :field, [])
    direction = Keyword.get(list, :direction, [])
    {String.to_atom(List.to_string(field)), String.to_atom(List.to_string(direction))}
  end

  defp parse_value(value) when is_list(value), do: List.to_string(value)
  defp parse_value(value), do: value
end
