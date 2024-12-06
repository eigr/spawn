defmodule Statestores.Adapters.MariaDBProjectionAdapterTest do
  use Statestores.DataCase
  alias Statestores.Adapters.MariaDBProjectionAdapter, as: Adapter
  alias Statestores.Schemas.Projection

  import Statestores.Util, only: [load_projection_adapter: 0]

  setup do
    repo = load_projection_adapter()
    %{repo: repo}
  end

  describe "create_table/1" do
    test "creates a table if it does not exist" do
      projection_name = "test_projections"

      assert {:ok, message} = Adapter.create_table(projection_name)
      assert message == "Table #{projection_name} created or already exists."
    end
  end

  describe "get_last/1" do
    test "returns the last inserted projection", ctx do
      repo = ctx.repo
      IO.inspect(repo)
      projection_name = "test_projections"

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

      assert {:ok, projection} = Adapter.get_last(projection_name)
      assert projection.projection_id == "proj_1"
    end
  end

  describe "get_last_by_projection_id/2" do
    test "returns the last inserted projection for a specific projection_id", ctx do
      repo = ctx.repo
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
               Adapter.get_last_by_projection_id(projection_name, projection_id)

      assert projection.projection_id == projection_id
    end
  end

  describe "get_all/3" do
    test "returns paginated projections", ctx do
      repo = ctx.repo
      projection_name = "test_projections"

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

      {:ok, result} = Adapter.get_all(projection_name, 1, 10)
      IO.inspect(result, label: "Pagination Result -----------")
      assert length(result.entries) == 10
      assert result.page_number == 1
    end
  end

  describe "search_by_metadata/5" do
    test "returns projections matching metadata key and value", ctx do
      repo = ctx.repo
      projection_name = "test_projections"
      metadata_key = "key"
      metadata_value = "value1"

      repo.save(%Projection{
        id: "1",
        projection_id: "proj_1",
        projection_name: projection_name,
        system: "test_system",
        metadata: %{"key" => "value1"},
        data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
        data: <<1, 2, 3>>,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      })

      repo.save(%Projection{
        id: "2",
        projection_id: "proj_2",
        projection_name: projection_name,
        system: "test_system",
        metadata: %{"key" => "value2"},
        data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
        data: <<1, 2, 3>>,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      })

      {:ok, result} = Adapter.get_all(projection_name)
      assert length(result.entries) == 2

      {:ok, result} =
        Adapter.search_by_metadata(
          projection_name,
          metadata_key,
          metadata_value
        )

      assert length(result.entries) == 1
      assert result.entries |> Enum.at(0) |> Map.get(:projection_id) == "proj_1"
    end
  end

  describe "search_by_projection_id_and_metadata/6" do
    test "returns projections matching projection_id and metadata", ctx do
      repo = ctx.repo
      projection_name = "test_projections"
      projection_id = "proj_1"
      metadata_key = "key"
      metadata_value = "value1"

      repo.save(%Projection{
        id: "1",
        projection_id: projection_id,
        projection_name: projection_name,
        system: "test_system",
        metadata: %{"key" => "value1"},
        data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
        data: <<1, 2, 3>>,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      })

      {:ok, result} =
        Adapter.search_by_projection_id_and_metadata(
          projection_name,
          projection_id,
          metadata_key,
          metadata_value
        )

      assert length(result.entries) == 1
      assert result.entries |> Enum.at(0) |> Map.get(:projection_id) == projection_id
    end
  end

  describe "fail for get_last_by_projection_id/2" do
    test "returns error if no matching projection_id found", _ctx do
      projection_name = "test_projections"
      non_existing_projection_id = "non_existing_proj"

      assert {:error, _error_msg} =
               Adapter.get_last_by_projection_id(
                 projection_name,
                 non_existing_projection_id
               )
    end
  end

  describe "fail get_last/1" do
    test "returns error if no projections exist", ctx do
      projection_name = "empty_projections_table"

      assert_raise MyXQL.Error, fn ->
        Adapter.get_last(projection_name)
      end
    end
  end

  describe "fail search_by_metadata/5" do
    test "returns no results for non-existing metadata key", ctx do
      repo = ctx.repo
      projection_name = "test_projections"
      invalid_metadata_key = "non_existing_key"
      metadata_value = "value1"

      {:ok, result} =
        Adapter.search_by_metadata(
          projection_name,
          invalid_metadata_key,
          metadata_value
        )

      assert length(result.entries) == 0
    end

    test "returns no results for non-existing metadata value", ctx do
      repo = ctx.repo
      projection_name = "test_projections"
      metadata_key = "key"
      invalid_metadata_value = "non_existing_value"

      {:ok, result} =
        Adapter.search_by_metadata(
          projection_name,
          metadata_key,
          invalid_metadata_value
        )

      assert length(result.entries) == 0
    end
  end

  describe "fail get_last_by_projection_id/2" do
    test "returns error if invalid parameters are provided", ctx do
      projection_name = "test_projections"
      invalid_projection_id = nil

      assert {:error, _message} =
               Adapter.get_last_by_projection_id(
                 projection_name,
                 invalid_projection_id
               )
    end
  end

  describe "fail get_all/3" do
    test "returns empty results if requested page is out of bounds", ctx do
      projection_name = "test_projections"

      {:ok, result} = Adapter.get_all(projection_name, 5, 10)

      IO.inspect(result,
        label: "fail get_all/3 ----------------------------------------------------------------"
      )

      assert length(result.entries) == 0
      # this totall create on test
      assert result.page_number == 1
    end
  end
end
