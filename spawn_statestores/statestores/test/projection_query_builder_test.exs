defmodule Projection.Query.BuilderTest do
  use ExUnit.Case, async: true

  alias Statestores.Projection.Query.QueryBuilder

  describe "build_query/4" do
    test "builds a basic select query" do
      select_clause = [:field1, :field2]
      conditions = []
      order_by = []

      expected_query =
        "SELECT tags->>'field1' AS field1, tags->>'field2' AS field2 FROM projections"

      assert QueryBuilder.build_query(select_clause, conditions, order_by, %{}) ==
               {expected_query, []}
    end

    test "builds a query with where condition" do
      select_clause = [:field1]
      conditions = [{:where, :level, "=", "'expert'"}]
      order_by = []
      expected_query = "SELECT tags->>'field1' AS field1 FROM projections WHERE level = 'expert'"

      assert QueryBuilder.build_query(select_clause, conditions, order_by, %{}) ==
               {expected_query, []}
    end

    test "builds a query with order by clause" do
      select_clause = [:field1]
      conditions = []
      order_by = [{:field1, :asc}]
      expected_query = "SELECT tags->>'field1' AS field1 FROM projections ORDER BY field1 ASC"

      assert QueryBuilder.build_query(select_clause, conditions, order_by, %{}) ==
               {expected_query, []}
    end

    test "builds a query with subquery in where condition" do
      select_clause = [:field1]
      conditions = [{:where, :level, "=", {:select, [:field1], [], []}}]
      order_by = []

      expected_query =
        "SELECT tags->>'field1' AS field1 FROM projections WHERE level = (SELECT tags->>'field1' AS field1 FROM projections)"

      assert QueryBuilder.build_query(select_clause, conditions, order_by, %{}) ==
               {expected_query, []}
    end
  end

  describe "build_query/4 with rank and aggregate functions" do
    test "builds query with rank over clause" do
      select_clause = [{:rank_over, :field1, :asc}]
      conditions = []
      order_by = []
      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query =
        "SELECT RANK() OVER (ORDER BY (tags->>'field1')::numeric ASC) FROM projections"

      assert query == expected_query
    end

    test "builds query with sum aggregate function" do
      select_clause = [{:sum, :field1, %{}}]
      conditions = []
      order_by = []
      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query = "SELECT SUM(tags->>'field1')::numeric FROM projections"
      assert query == expected_query
    end

    test "builds query with avg aggregate function" do
      select_clause = [{:avg, :field1, %{}}]
      conditions = []
      order_by = []
      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query = "SELECT AVG(tags->>'field1')::numeric FROM projections"
      assert query == expected_query
    end

    test "builds query with min aggregate function" do
      select_clause = [{:min, :field1, %{}}]
      conditions = []
      order_by = []
      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query = "SELECT MIN(tags->>'field1')::numeric FROM projections"
      assert query == expected_query
    end

    test "builds query with max aggregate function" do
      select_clause = [{:max, :field1, %{}}]
      conditions = []
      order_by = []
      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query = "SELECT MAX(tags->>'field1')::numeric FROM projections"
      assert query == expected_query
    end

    test "builds query with multiple functions (rank, sum, avg)" do
      select_clause = [
        {:sum, :field1, %{}},
        {:avg, :field2, %{}},
        {:rank_over, :field3, :desc}
      ]

      conditions = []
      order_by = []
      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query =
        "SELECT SUM(tags->>'field1')::numeric, AVG(tags->>'field2')::numeric, RANK() OVER (ORDER BY (tags->>'field3')::numeric DESC) FROM projections"

      assert query == expected_query
    end
  end

  describe "build_query/4 with complex queries" do
    test "builds query with group by clause" do
      select_clause = [{:sum, :field1, %{}}]
      conditions = []
      order_by = []
      group_by = [:field1]

      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, group_by)

      expected_query = "SELECT SUM(tags->>'field1')::numeric FROM projections GROUP BY field1"

      assert query == expected_query
    end

    test "builds query with group by and aggregate functions" do
      select_clause = [
        {:sum, :field1, %{}},
        {:avg, :field2, %{}}
      ]

      conditions = []
      order_by = []
      group_by = [:field1]

      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, group_by)

      expected_query =
        "SELECT SUM(tags->>'field1')::numeric, AVG(tags->>'field2')::numeric FROM projections GROUP BY field1"

      assert query == expected_query
    end

    test "build_query/4 builds a query with subquery in SELECT clause" do
      select_clause = [
        :player_id,
        :points,
        {:subquery, "SELECT COUNT(*) FROM projections AS t2 WHERE t2.points > t1.points", "rank"}
      ]

      conditions = []
      order_by = []

      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query =
        "SELECT tags->>'player_id' AS player_id, tags->>'points' AS points, (SELECT COUNT(*) FROM projections AS t2 WHERE t2.points > t1.points) AS rank FROM projections"

      assert query == expected_query
    end
  end

  describe "build_query/4 with invalid GROUP BY" do
    test "raises an exception when GROUP BY is used without an aggregation function" do
      select_clause = [:some_field]
      conditions = []
      order_by = []
      group_by = [:some_field]

      assert_raise ArgumentError,
                   ~r/GROUP BY must be used in conjunction with aggregation functions/,
                   fn ->
                     QueryBuilder.build_query(select_clause, conditions, order_by, group_by)
                   end
    end
  end

  describe "build_query/5 with HAVING clause" do
    test "generates SQL with valid HAVING clause" do
      select_clause = [{:sum, :price, []}]
      conditions = []
      order_by = []
      group_by = [:category]
      having_clause = [{:having, "SUM(price)", ">", 100}]

      {query, _params} =
        QueryBuilder.build_query(select_clause, conditions, order_by, group_by, having_clause)

      assert query ==
               "SELECT SUM(tags->>'price')::numeric FROM projections GROUP BY category HAVING SUM(price) > 100"
    end

    test "returns empty HAVING when no conditions are provided" do
      select_clause = [{:sum, :price, []}]
      conditions = []
      order_by = []
      group_by = [:price]

      {query, _params} =
        QueryBuilder.build_query(select_clause, conditions, order_by, group_by, [])

      refute query =~ "HAVING"
    end
  end
end
