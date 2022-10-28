defmodule Actor.ActorTest do
  use ExUnit.Case

  defmodule Actor.MyActor do
    use SpawnSdk.Actor,
      name: "my-actor",
      state_type: Eigr.Spawn.Actor.MyState

    alias Eigr.Spawn.Actor.{MyState, MyMessageRequest, MyMessageResponse}

    @impl true
    def handle_command(
          {"sum", %MyMessageRequest{id: id, data: data}},
          %Context{state: %MyState{}} = ctx
        ) do
      current_state = ctx.state
      new_state = current_state

      response = MyMessageResponse.new(id: id, data: data)
      result = %Value{state: new_state, value: response}

      {:ok, result}
    end
  end

  describe "meta/1" do
    test "assert meta fields" do
      assert "my-actor" = Actor.MyActor.__meta__(:name)
      assert Eigr.Spawn.Actor.MyState = Actor.MyActor.__meta__(:state_type)
    end

    test "get defaults" do
      assert Actor.MyActor.__meta__(:abstract) == false
      assert true = Actor.MyActor.__meta__(:persistent)
      assert 10_000 = Actor.MyActor.__meta__(:deactivate_timeout)
      assert 2_000 = Actor.MyActor.__meta__(:snapshot_timeout)
    end
  end

  describe "handle_command/2" do
    test "simple call for valid pattern match" do
      id = Faker.Superhero.name()
      data = Faker.StarWars.character()
      ctx = %SpawnSdk.Context{state: Eigr.Spawn.Actor.MyState.new(id: "1", value: 1)}

      request = Eigr.Spawn.Actor.MyMessageRequest.new(id: id, data: data)
      Actor.MyActor.handle_command({"sum", request}, ctx)

      assert {:ok,
              %SpawnSdk.Value{
                state: %Eigr.Spawn.Actor.MyState{id: "1", value: 1},
                value: %Eigr.Spawn.Actor.MyMessageResponse{}
              }} = Actor.MyActor.handle_command({"sum", request}, ctx)
    end
  end
end
