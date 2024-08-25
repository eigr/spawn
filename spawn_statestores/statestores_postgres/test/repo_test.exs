defmodule StatestoresPostgresTest.RepoTest do
  use Statestores.DataCase
  alias Statestores.Schemas.Snapshot
  import Statestores.Util, only: [load_snapshot_adapter: 0, generate_key: 1]

  setup do
    %{system: "test-system"}
  end

  test "insert new snapshot does not create historical snapshot", ctx do
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
      revision: 1,
      tags: %{},
      data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
      data: "Hello Joe"
    }

    _result = repo.save(event)

    # Ensure no historical snapshot is created
    historical_events = repo.get_all_snapshots_by_key(key)
    assert length(historical_events) == 0
  end

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
    # IO.inspect(actor_state, label: "First event")

    # Ensure the initial state is correct
    assert actor_state.data == "Hello Joe"
    assert actor_state.revision == 1

    # Simulate an update after some time
    Process.sleep(1000)
    updated_event = %{event | data: "new joe"}
    _result = repo.save(updated_event)
    actor_state2 = repo.get_by_key(key)
    # IO.inspect(actor_state2, label: "Updated event")

    # Validate that the current_snapshots table was updated
    assert actor_state2.data == "new joe"
    assert actor_state2.revision == 2
    assert actor_state.updated_at != actor_state2.updated_at

    # Validate that a record was added to historical_snapshots
    historical_events = repo.get_all_snapshots_by_key(key)
    assert length(historical_events) == 1

    historical_event = List.first(historical_events)
    # IO.inspect(historical_events, label: "All Events")
    assert historical_event.data == "Hello Joe"
    assert historical_event.revision == 1
  end

  test "revision increments correctly on multiple updates", ctx do
    %{system: system} = ctx

    actor = "mike"
    id = %{name: actor, system: system}
    key = generate_key(id)
    repo = load_snapshot_adapter()

    # Insert initial snapshot
    event = %Snapshot{
      id: key,
      system: system,
      actor: actor,
      status: "ACTIVATED",
      node: Atom.to_string(Node.self()),
      revision: 0,
      tags: %{},
      data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
      data: "Initial"
    }

    _result = repo.save(event)

    # First update
    Process.sleep(1000)
    first_update = %{event | data: "First Update"}
    _result = repo.save(first_update)

    # Second update
    Process.sleep(1000)
    second_update = %{first_update | data: "Second Update"}
    _result = repo.save(second_update)

    # Third update
    Process.sleep(1000)
    third_update = %{second_update | data: "Third Update"}
    _result = repo.save(third_update)

    # Validate current snapshot
    # TODO: The implementation should include the snapshot table when using get_all_snapshots...
    # This needs to be implemented in the future and this test should be changed to reflect the implementation
    final_state = repo.get_by_key(key)
    assert final_state.data == "Third Update"
    assert final_state.revision == 4

    # Validate historical snapshots
    historical_events = repo.get_all_snapshots_by_key(key)
    assert length(historical_events) == 3

    # Check the data and revision for each historical snapshot
    assert Enum.at(historical_events, 0).data == "Initial"
    assert Enum.at(historical_events, 0).revision == 1

    assert Enum.at(historical_events, 1).data == "First Update"
    assert Enum.at(historical_events, 1).revision == 2

    assert Enum.at(historical_events, 2).data == "Second Update"
    assert Enum.at(historical_events, 2).revision == 3
  end

  test "insert! should persist a valid Event in snapshot", ctx do
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
      revision: 1,
      tags: %{},
      data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
      data: "Hello Joe"
    }

    _result = repo.save(event)
    actor_state = repo.get_by_key(key)

    assert actor_state.data == "Hello Joe"
    assert actor_state.revision == 1

    # Validate that no historical record was created on the first insert
    historical_events = repo.get_all_snapshots_by_key(key)
    assert length(historical_events) == 0
  end

  test "get_by_key_and_revision/2 should return the correct historical snapshot", ctx do
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
      revision: 1,
      tags: %{},
      data_type: "type.googleapis.com/io.eigr.spawn.example.MyState",
      data: "Hello Joe"
    }

    _result = repo.save(event)
    Process.sleep(1000)

    updated_event = %{event | data: "Hello Joe"}
    _result = repo.save(updated_event)

    # Retrieve the historical snapshot by revision
    historical_event = repo.get_by_key_and_revision(key, 1)

    assert historical_event.data == "Hello Joe"
    assert historical_event.revision == 1
  end
end
