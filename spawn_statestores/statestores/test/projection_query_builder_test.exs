defmodule Projection.Query.BuilderTest do
  use ExUnit.Case, async: true

  alias Statestores.Projection.Query.QueryBuilder

  describe "build_query/4" do
    test "builds a basic select query" do
      select_clause = [:field1, :field2]
      conditions = []
      order_by = []
      expected_query = "SELECT tags->>'field1' AS field1, tags->>'field2' AS field2 FROM projections"
      assert QueryBuilder.build_query(select_clause, conditions, order_by, %{}) == {expected_query, []}
    end

    test "builds a query with where condition" do
      select_clause = [:field1]
      conditions = [{:where, :level, "=", "'expert'"}]
      order_by = []
      expected_query = "SELECT tags->>'field1' AS field1 FROM projections WHERE level = 'expert'"
      assert QueryBuilder.build_query(select_clause, conditions, order_by, %{}) == {expected_query, []}
    end

    test "builds a query with order by clause" do
      select_clause = [:field1]
      conditions = []
      order_by = [{:field1, :asc}]
      expected_query = "SELECT tags->>'field1' AS field1 FROM projections ORDER BY field1 ASC"
      assert QueryBuilder.build_query(select_clause, conditions, order_by, %{}) == {expected_query, []}
    end

    test "builds a query with subquery in where condition" do
      select_clause = [:field1]
      conditions = [{:where, :level, "=", {:select, [:field1], [], []}}]
      order_by = []
      expected_query = "SELECT tags->>'field1' AS field1 FROM projections WHERE level = (SELECT tags->>'field1' AS field1 FROM projections)"
      assert QueryBuilder.build_query(select_clause, conditions, order_by, %{}) == {expected_query, []}
    end
  end

  describe "build_query/4 with rank and aggregate functions" do
    test "builds query with rank over clause" do
      select_clause = [:rank_over, :field1, :asc]
      conditions = []
      order_by = []
      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query = "SELECT RANK() OVER (ORDER BY (tags->>'field1')::numeric ASC) FROM projections"
      assert query == expected_query
    end

    test "builds query with sum aggregate function" do
      select_clause = [:subquery, {:sum, :field1, %{}}]
      conditions = []
      order_by = []
      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query = "SELECT SUM(tags->>'field1')::numeric FROM projections"
      assert query == expected_query
    end

    test "builds query with avg aggregate function" do
      select_clause = [:subquery, {:avg, :field1, %{}}]
      conditions = []
      order_by = []
      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query = "SELECT AVG(tags->>'field1')::numeric FROM projections"
      assert query == expected_query
    end

    test "builds query with min aggregate function" do
      select_clause = [:subquery, {:min, :field1, %{}}]
      conditions = []
      order_by = []
      {query, _params} = QueryBuilder.build_query(select_clause, conditions, order_by, %{})

      expected_query = "SELECT MIN(tags->>'field1')::numeric FROM projections"
      assert query == expected_query
    end

    test "builds query with max aggregate function" do
      select_clause = [:subquery, {:max, :field1, %{}}]
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

      expected_query = "SELECT SUM(tags->>'field1')::numeric, AVG(tags->>'field2')::numeric, RANK() OVER (ORDER BY (tags->>'field3')::numeric DESC) FROM projections"
      assert query == expected_query
    end
  end
end
  