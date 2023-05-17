defmodule StatestoresSqliteTest.RepoTest do
  use Statestores.DataCase
  alias Statestores.Schemas.Event
  import Statestores.Util, only: [load_adapter: 0, generate_key: 2]

  setup do
    %{system: "test-system"}
  end

  test "insert! should persist an valid Event", ctx do
    %{system: system} = ctx

    actor = "mike"
    key = generate_key(system, actor)
    repo = load_adapter()

    event = %Event{
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

    actor = "mike"
    key = generate_key(system, actor)
    repo = load_adapter()

    event = %Event{
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
