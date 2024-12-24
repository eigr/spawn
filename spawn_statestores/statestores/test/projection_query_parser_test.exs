defmodule Projection.Query.ParserTest do
  use ExUnit.Case, async: true

  alias Statestores.Projection.Query.Parser

  describe "parse/1" do
    test "parses select clause with no conditions and no order by" do
      dsl = "select field1, field2"
      expected = {[:field1, :field2], [], []}
      assert Parser.parse(dsl) == expected
    end

    test "parses select clause with subquery" do
      dsl = "select sum(field1) where level = 'expert'"
      expected = {[:subquery, {:sum, :field1, %{level: "expert"}}], [], []}
      assert Parser.parse(dsl) == expected
    end

    test "parses select clause with order by" do
      dsl = "select field1, field2 order by field1 asc"
      expected = {[:field1, :field2], [], [{:field1, :asc}]}
      assert Parser.parse(dsl) == expected
    end

    test "parses select clause with where and order by" do
      dsl = "select field1 where level = 'expert' order by field1 desc"
      expected = {[:field1], [], [{:field1, :desc}]}
      assert Parser.parse(dsl) == expected
    end
  end

  describe "parse/1 with rank and aggregate functions" do
    test "parses rank over clause" do
      dsl = "select rank_over(field1, asc)"
      expected = {[:rank_over, :field1, :asc], [], []}
      assert Parser.parse(dsl) == expected
    end

    test "parses sum aggregate function" do
      dsl = "select sum(field1) where level = 'expert'"
      expected = {[:subquery, {:sum, :field1, %{level: "expert"}}], [], []}
      assert Parser.parse(dsl) == expected
    end

    test "parses avg aggregate function" do
      dsl = "select avg(field1)"
      expected = {[:subquery, {:avg, :field1, %{}}], [], []}
      assert Parser.parse(dsl) == expected
    end

    test "parses min aggregate function" do
      dsl = "select min(field1)"
      expected = {[:subquery, {:min, :field1, %{}}], [], []}
      assert Parser.parse(dsl) == expected
    end

    test "parses max aggregate function" do
      dsl = "select max(field1)"
      expected = {[:subquery, {:max, :field1, %{}}], [], []}
      assert Parser.parse(dsl) == expected
    end

    test "parses multiple functions together" do
      dsl = "select sum(field1), avg(field2), rank_over(field3, desc)"

      expected =
        {[
           {:sum, :field1, %{}},
           {:avg, :field2, %{}},
           {:rank_over, :field3, :desc}
         ], [], []}

      assert Parser.parse(dsl) == expected
    end
  end
end
