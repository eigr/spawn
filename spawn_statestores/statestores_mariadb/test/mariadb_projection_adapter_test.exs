defmodule Statestores.Adapters.MariaDBProjectionAdapterTest do
  use Statestores.DataCase
  alias Statestores.Adapters.MariaDBProjectionAdapter
  alias Statestores.Schemas.Projection

  import Statestores.Util, only: [load_projection_adapter: 0]

  # Import helper functions if needed for insertions
  # import Ecto.Query

  describe "create_table/1" do
    test "creates a table if it does not exist", _ctx do
      projection_name = "test_projections"

      assert {:ok, message} = MariaDBProjectionAdapter.create_table(projection_name)
      assert message == "Table #{projection_name} created or already exists."
    end
  end

  describe "get_last/1" do
    test "returns the last inserted projection", ctx do
      repo = load_projection_adapter()
      IO.inspect(repo)
      projection_name = "test_projections"

      # Insert mock data into the projection table
      {:ok, _} =
        repo.save(%Projection{
          id: "123",
          projection_id: "proj_1",
          projection_name: projection_name,
          system: "test_system",
          metadata: %{"key" => "value"},
          data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
          data: <<1, 2, 3>>,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        })

      assert {:ok, projection} = MariaDBProjectionAdapter.get_last(projection_name)
      assert projection.projection_id == "proj_1"
    end
  end

  describe "get_last_by_projection_id/2" do
    test "returns the last inserted projection for a specific projection_id", ctx do
      repo = load_projection_adapter()
      projection_name = "test_projections"
      projection_id = "proj_1"

      {:ok, _} =
        repo.save(%Projection{
          id: "123",
          projection_id: projection_id,
          projection_name: projection_name,
          system: "test_system",
          metadata: %{"key" => "value"},
          data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
          data: <<1, 2, 3>>,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        })

      assert {:ok, projection} =
               MariaDBProjectionAdapter.get_last_by_projection_id(projection_name, projection_id)

      assert projection.projection_id == projection_id
    end
  end

  describe "get_all/3" do
    test "returns paginated projections", ctx do
      repo = load_projection_adapter()
      projection_name = "test_projections"

      # Insert multiple records for pagination
      Enum.each(1..20, fn n ->
        repo.save(%Projection{
          id: "#{n}",
          projection_id: "proj_#{n}",
          projection_name: projection_name,
          system: "test_system",
          metadata: %{"key" => "value#{n}"},
          data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
          data: <<1, 2, 3>>,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        })
      end)

      {:ok, result} = MariaDBProjectionAdapter.get_all(projection_name, 1, 10)
      assert length(result.entries) == 10
      assert result.page_number == 1
    end
  end

  # describe "search_by_metadata/5" do
  #   test "returns projections matching metadata key and value", ctx do
  #     repo = load_projection_adapter()
  #     projection_name = "test_projections"
  #     metadata_key = "key"
  #     metadata_value = "value1"

  #     repo.save(%Projection{
  #       projection_id: "proj_1",
  #       projection_name: projection_name,
  #       system: "test_system",
  #       metadata: %{"key" => "value1"},
  #       inserted_at: DateTime.utc_now(),
  #       updated_at: DateTime.utc_now()
  #     })

  #     repo.save(%Projection{
  #       projection_id: "proj_2",
  #       projection_name: projection_name,
  #       system: "test_system",
  #       metadata: %{"key" => "value2"},
  #       inserted_at: DateTime.utc_now(),
  #       updated_at: DateTime.utc_now()
  #     })

  #     {:ok, result} =
  #       MariaDBProjectionAdapter.search_by_metadata(
  #         projection_name,
  #         metadata_key,
  #         metadata_value,
  #         1,
  #         10
  #       )

  #     assert length(result.entries) == 1
  #     assert result.entries |> Enum.at(0) |> Map.get(:projection_id) == "proj_1"
  #   end
  # end

  # describe "search_by_projection_id_and_metadata/6" do
  #   test "returns projections matching projection_id and metadata", ctx do
  #     repo = load_projection_adapter()
  #     projection_name = "test_projections"
  #     projection_id = "proj_1"
  #     metadata_key = "key"
  #     metadata_value = "value1"

  #     repo.save(%Projection{
  #       projection_id: projection_id,
  #       projection_name: projection_name,
  #       system: "test_system",
  #       metadata: %{"key" => "value1"},
  #       inserted_at: DateTime.utc_now(),
  #       updated_at: DateTime.utc_now()
  #     })

  #     {:ok, result} =
  #       MariaDBProjectionAdapter.search_by_projection_id_and_metadata(
  #         projection_name,
  #         projection_id,
  #         metadata_key,
  #         metadata_value,
  #         1,
  #         10
  #       )

  #     assert length(result.entries) == 1
  #     assert result.entries |> Enum.at(0) |> Map.get(:projection_id) == projection_id
  #   end
  # end
end
