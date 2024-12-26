defmodule Statestores.Projection.Query.ParserTest do
  use ExUnit.Case, async: true

  alias Statestores.Projection.Query.Parser

  # describe "parse/1 simple query" do
  #   test "parses select clause with no conditions and no order by" do
  #     dsl = "select field1, field2"
  #     assert {[:field1, :field2], [], []} == Parser.parse(dsl)
  #   end

  #   test "parses select clause with subquery" do
  #     dsl = "select sum(field1) where level = 'expert'"
  #     assert {[:subquery, {:sum, :field1, %{level: "expert"}}], [], []} == Parser.parse(dsl)
  #   end
  # end

  describe "parse/1 group by expressions" do
    test "parses query with GROUP BY and HAVING clauses" do
      # dsl = "select sum(points) as total_points group by team having total_points > 100 order by total_points desc"
      # dsl = "select points, team group by team having sum(points) > 100 order by points desc"
      dsl =
        "select sum(points) as total where age > 30 and salary <= 5000 group by department having count(employees) > 10 order by total desc"

      {select, where, group_by, having, order_by} = Parser.parse(dsl)

      assert select == [{:sum, :points, []}]
      assert where == []
      assert group_by == [:team]
      assert having == [{:having, :total_points, ">", 100}]
      assert order_by == [{:total_points, :desc}]
    end

    # test "parses query without HAVING clause" do
    #   dsl = "select sum(points) as total_points group by team order by total_points desc"

    #   {select, where, group_by, having, order_by} = Parser.parse(dsl)

    #   assert select == [{:sum, :points, []}]
    #   assert where == []
    #   assert group_by == [:team]
    #   assert having == []
    #   assert order_by == [{:total_points, :desc}]
    # end
  end
end
