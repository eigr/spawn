defmodule Statestores.Projection.QueryExecutor do
  @moduledoc """
  Query Executor module for executing queries written in a custom DSL.

  ## Usage Examples

  ### Example 1: Basic Query with Literal Values

  ```elixir
  dsl = "select name, count(*) where name = 'John' and active = true order by created_at desc"

  Statestores.Projection.QueryExecutor.execute(MyApp.Repo, dsl)
  ```

  **Generated SQL Query:**

  ```sql
  SELECT tags->>'name' AS name, COUNT(*)
  FROM projections
  WHERE (tags->>'name') = 'John' AND (tags->>'active')::boolean = true
  ORDER BY tags->>'created_at' DESC;
  ```

  **Parameters Substituted:**

  No parameters, as all values are literals.

  ---

  ### Example 2: Query with Binds

  ```elixir
  dsl = "select name, count(*) where name = :name and active = :active order by created_at desc"

  binds = %{"name" => "Jane", "active" => true}

  Statestores.Projection.QueryExecutor.execute(MyApp.Repo, dsl, binds)
  ```

  **Generated SQL Query:**

  ```sql
  SELECT tags->>'name' AS name, COUNT(*)
  FROM projections
  WHERE (tags->>'name') = $1 AND (tags->>'active')::boolean = $2
  ORDER BY tags->>'created_at' DESC;
  ```

  **Parameters Substituted:**

  ```plaintext
  $1 = "Jane"
  $2 = true
  ```

  ---

  ### Example 3: Query with Aggregations

  ```elixir
  dsl = "select avg(age), max(score) where active = true"

  Statestores.Projection.QueryExecutor.execute(MyApp.Repo, dsl)
  ```

  **Generated SQL Query:**

  ```sql
  SELECT AVG(tags->>'age'::numeric), MAX(tags->>'score'::numeric)
  FROM projections
  WHERE (tags->>'active')::boolean = true;
  ```

  **Parameters Substituted:**

  No parameters, as all values are literals.

  --- 

  ### Example 4: Query with Window Functions

  ```elixir
  iex> dsl = "select player_id, points, rank() over(order by points desc)"
      iex> Statestores.Projection.QueryExecutor.execute(MyApp.Repo, dsl)
      :ok
  ```

  **Generated SQL Query:**
  
  ```sql
    SELECT
        tags->>'player_id' AS player_id,
        (tags->>'points')::numeric AS points,
        RANK() OVER (ORDER BY (tags->>'points')::numeric DESC) AS rank
    FROM
        projections;
  ``` 

  **Parameters Substituted:**

  No parameters, as all values are literals.
  """

  import Ecto.Query

  alias Statestores.Projection.Query.QueryBuilder
  alias Statestores.Projection.Query.Parser, as: DSLParser

  def execute(repo, dsl, binds \\ %{}) do
    {select_clause, conditions, order_by} = DSLParser.parse(dsl)
    {query, params} = QueryBuilder.build_query(select_clause, conditions, order_by, binds)

    Ecto.Adapters.SQL.query!(repo, query, Enum.map(params, &elem(&1, 1)))
  end
end
