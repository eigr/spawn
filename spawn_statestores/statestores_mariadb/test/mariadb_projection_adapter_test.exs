defmodule StatestoresMariaDB.MariaDBProjectionAdapterTest do
  use Statestores.DataCase, async: false

  alias Statestores.Manager.StateManager
  alias Test.TestMessage

  import Statestores.Util, only: [load_projection_adapter: 0]

  setup do
    repo = load_projection_adapter()
    table_name = "test_messages"

    data = %TestMessage{
      name: "test_user",
      age: 25,
      balance: 100.50,
      active: true,
      document: "binary-data",
      address: %TestMessage.Address{
        street: "123 Main St",
        city: "Testville",
        state: "TS",
        zip_code: "12345",
        country: %TestMessage.Address.Country{
          name: "Test Country",
          code: "TC"
        }
      },
      created_at: DateTime.utc_now(),
      metadata: %{"key" => "value"},
      tags: ["elixir", "protobuf"],
      attributes: %{"role" => "admin"}
    }

    {:ok, _} = Ecto.Adapters.SQL.query(repo, "DROP TABLE IF EXISTS #{table_name}")
    :ok = StateManager.projection_create_or_update_table(TestMessage, table_name)

    %{repo: repo, table_name: table_name, data: data}
  end

  test "add new field to the table if schema changes", ctx do
    %{
      repo: repo,
      data: data,
      table_name: table_name
    } = ctx

    :ok = StateManager.projection_create_or_update_table(TestMessage, table_name)

    {:ok, _result} = Ecto.Adapters.SQL.query(repo, "ALTER TABLE #{table_name} DROP COLUMN age")

    :ok = StateManager.projection_create_or_update_table(TestMessage, table_name)

    data = %{data | age: 34}

    :ok = StateManager.projection_upsert(TestMessage, table_name, data)

    {:ok, result} =
      StateManager.projection_query(
        TestMessage,
        "SELECT age, name FROM test_messages WHERE name = :name",
        %{name: "test_user"},
        []
      )

    assert [%TestMessage{age: 34}] = result
  end

  test "performs upsert and query operations", ctx do
    %{table_name: table_name, data: data} = ctx

    :ok = StateManager.projection_upsert(TestMessage, table_name, data)

    {:ok, result} =
      StateManager.projection_query(
        TestMessage,
        "SELECT age, name FROM test_messages WHERE name = :name",
        %{name: "test_user"},
        []
      )

    assert [%TestMessage{name: "test_user"}] = result

    data = %{data | age: 30}

    :ok = StateManager.projection_upsert(TestMessage, table_name, data)

    {:ok, result} =
      StateManager.projection_query(
        TestMessage,
        "SELECT age, name FROM test_messages WHERE name = :name",
        %{name: "test_user"},
        []
      )

    assert [%TestMessage{age: 30}] = result
  end

  test "performs upsert and query operations with pagination", ctx do
    %{table_name: table_name, data: data} = ctx

    Enum.each(1..10, fn item ->
      :ok = StateManager.projection_upsert(TestMessage, table_name, %{data | name: "#{item}"})
    end)

    {:ok, result} =
      StateManager.projection_query(
        TestMessage,
        "SELECT * FROM test_messages ORDER BY name",
        %{name: "test_user"},
        page_size: 3,
        page: 2
      )

    assert [%TestMessage{name: "3"}, %TestMessage{name: "4"}, %TestMessage{name: "5"}] = result
  end

  test "performs a query with no parameters matching query", ctx do
    %{table_name: table_name, data: data} = ctx

    :ok = StateManager.projection_upsert(TestMessage, table_name, data)

    assert {:error, _result} =
             StateManager.projection_query(
               TestMessage,
               "SELECT age, name FROM test_messages WHERE name = :name",
               %{},
               []
             )
  end

  test "performs a query with more unecessary parameters", ctx do
    %{table_name: table_name, data: data} = ctx

    data = %{data | enum_test: nil}

    :ok = StateManager.projection_upsert(TestMessage, table_name, data)

    {:ok, result} =
      StateManager.projection_query(
        TestMessage,
        "SELECT * FROM test_messages",
        %{metadata: nil},
        []
      )

    assert [%TestMessage{name: "test_user"}] = result
  end
end
