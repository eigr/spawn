defmodule StatestoresPostgresTest.RepoTest do
  use Statestores.DataCase
  alias Statestores.Schemas.Snapshot
  import Statestores.Util, only: [load_snapshot_adapter: 0, generate_key: 1]

  setup do
    %{system: "test-system"}
  end

  # test "insert! should persist a valid Event in snapshot", ctx do
  #   %{system: system} = ctx

  #   actor = "mike"
  #   id = %{name: actor, system: system}
  #   key = generate_key(id)
  #   repo = load_snapshot_adapter()

  #   event = %Snapshot{
  #     id: key,
  #     system: system,
  #     actor: actor,
  #     status: "ACTIVATED",
  #     node: Atom.to_string(Node.self()),
  #     revision: 1,
  #     tags: %{},
  #     data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
  #     data: "Hello Joe"
  #   }

  #   _result = repo.save(event)
  #   actor_state = repo.get_by_key(key)

  #   assert actor_state.data == "Hello Joe"
  #   assert actor_state.revision == 1

  #   # Validate that no historical record was created on the first insert
  #   historical_events = repo.get_all_snapshots_by_key(key)
  #   assert length(historical_events) == 0
  # end

  test "insert! should update current_snapshots and create historical snapshot on update", ctx do
    %{system: system} = ctx

    actor = "mike"
    id = %{name: actor, system: system}
    key = generate_key(id)
    repo = load_snapshot_adapter()

    event = %Snapshot{
      id: key,
      system: system,
      actor: actor,
      status: "ACTIVATED",
      node: Atom.to_string(Node.self()),
      tags: %{},
      data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
      data: "Hello Joe"
    }

    _result = repo.save(event)
    actor_state = repo.get_by_key(key)
    IO.inspect(actor_state, label: "First event")

    # Ensure the initial state is correct
    assert actor_state.data == "Hello Joe"
    assert actor_state.revision == 1

    # Simulate an update after some time
    Process.sleep(1000)
    updated_event = %{event | data: "new joe"}
    _result = repo.save(updated_event)
    actor_state2 = repo.get_by_key(key)
    IO.inspect(actor_state2, label: "Updated event")

    # Validate that the current_snapshots table was updated
    assert actor_state2.data == "new joe"
    assert actor_state2.revision == 2
    assert actor_state.updated_at != actor_state2.updated_at

    # Validate that a record was added to historical_snapshots
    historical_events = repo.get_all_snapshots_by_key(key)
    assert length(historical_events) == 1

    historical_event = List.first(historical_events)
    IO.inspect(historical_events, label: "All Events")
    assert historical_event.data == "Hello Joe"
    assert historical_event.revision == 1
  end

  # test "get_by_key_and_revision/2 should return the correct historical snapshot", ctx do
  #   %{system: system} = ctx

  #   actor = "mike"
  #   id = %{name: actor, system: system}
  #   key = generate_key(id)
  #   repo = load_snapshot_adapter()

  #   event = %Snapshot{
  #     id: key,
  #     system: system,
  #     actor: actor,
  #     status: "ACTIVATED",
  #     node: Atom.to_string(Node.self()),
  #     revision: 1,
  #     tags: %{},
  #     data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
  #     data: "Hello Joe"
  #   }

  #   _result = repo.save(event)
  #   Process.sleep(1000)

  #   updated_event = %{event | data: "Hello Joe"}
  #   _result = repo.save(updated_event)

  #   # Retrieve the historical snapshot by revision
  #   historical_event = repo.get_by_key_and_revision(key, 1)

  #   assert historical_event.data == "Hello Joe"
  #   assert historical_event.revision == 1
  # end
end
