defmodule StatestoresMssqlTest.RepoTest do
  use Statestores.DataCase
  alias Statestores.Schemas.Snapshot
  import Statestores.Util, only: [load_snapshot_adapter: 0, generate_key: 1]

  setup do
    %{system: "test-system"}
  end

  test "insert! should persist an valid Event", ctx do
    %{system: system} = ctx

    actor = "mike"
    id = %{name: actor, system: system}
    key = generate_key(id)
    repo = load_snapshot_adapter()

    event = %Snapshot{
      id: key,
      system: system,
      actor: actor,
      revision: 0,
      tags: %{},
      data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
      data: "Hello Joe"
    }

    _result = repo.save(event)
    actor_state = repo.get_by_key(key)

    assert actor_state.data == "Hello Joe"
  end

  test "insert! should update when inserted before", ctx do
    %{system: system} = ctx
    repo = load_snapshot_adapter()

    actor = "mike"
    id = %{name: actor, system: system}
    key = generate_key(id)

    event = %Snapshot{
      system: "test-system",
      actor: actor,
      revision: 0,
      tags: %{},
      data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
      data: "Hello Joe"
    }

    _result = repo.save(event)
    actor_state = repo.get_by_key(key)

    Process.sleep(1000)
    event = %{event | data: "new joe"}
    _result = repo.save(event)
    actor_state2 = repo.get_by_key(key)

    refute is_nil(actor_state.updated_at)
    refute is_nil(actor_state2.updated_at)
    assert actor_state.updated_at != actor_state2.updated_at
    assert actor_state2.data == "new joe"
  end
end
