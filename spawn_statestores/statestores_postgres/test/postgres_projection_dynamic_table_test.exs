defmodule Statestores.Adapters.PostgresProjectionDynamicTableTest do
    use Statestores.DataCase
    alias Statestores.Projection.DynamicTableCreator
    alias Statestores.Projection.Query.TableDataHandler
    alias Test.TestMessage

    import Statestores.Util, only: [load_projection_adapter: 0]

    setup do
      repo = load_projection_adapter()
      table_name = "test_messages"

      :ok = DynamicTableCreator.create_table(Repo, TestMessage, table_name)

      %{repo: repo, table_name: table_name}
    end
  
    test "performs upsert and query operations", %{repo: repo, table_name: table_name} do
      data = %TestMessage{
        name: "test_user",
        age: 25,
        balance: 100.50,
        active: true,
        document: "binary-data",
        address: %TestMessage.Address{street: "123 Main St", city: "Testville", state: "TS", zip_code: "12345"},
        created_at: DateTime.utc_now(),
        metadata: %{"key" => "value"},
        tags: ["elixir", "protobuf"],
        attributes: %{"role" => "admin"}
      }
  
      :ok = DynamicTableDataHandler.upsert(repo, TestMessage, table_name, data)
  
      result = DynamicTableDataHandler.query(repo, TestMessage, table_name, %{name: "test_user"})
      assert [%TestMessage{name: "test_user"}] = result
  
      :ok = DynamicTableDataHandler.update(repo, TestMessage, table_name, %{name: "test_user"}, %{age: 30})
  
      result = DynamicTableDataHandler.query(repo, TestMessage, table_name, %{name: "test_user"})
      assert [%TestMessage{age: 30}] = result
    end
  end
  