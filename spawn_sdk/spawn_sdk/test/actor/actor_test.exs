defmodule Actor.ActorTest do
  use ExUnit.Case

  defmodule Actor.MyActor do
    use SpawnSdk.Actor,
      abstract: true,
      persistent: false,
      state_type: Eigr.Spawn.Actor.MyState

    alias Eigr.Spawn.Actor.{MyMessageRequest, MyMessageResponse}

    defact sum(%MyMessageRequest{id: id, data: data}, %Context{} = ctx) do
      current_state = ctx.state
      new_state = current_state

      response = MyMessageResponse.new(id: id, data: data)
      result = %Value{state: new_state, value: response}

      {:ok, result}
    end

    defact pipe_caller(%MyMessageRequest{data: data}, %Context{} = _ctx) do
      %Value{}
      |> Value.value(MyMessageResponse.new(data: data))
      |> Value.pipe(Pipe.to("second_actor", "caller_name"))
      |> Value.void()
    end

    defact forward_caller(%MyMessageRequest{data: data}, %Context{} = _ctx) do
      %Value{}
      |> Value.value(MyMessageResponse.new(data: "first_actor_value"))
      |> Value.forward(Forward.to("second_actor", "forward_caller_name"))
      |> Value.void()
    end
  end

  defmodule Actor.OtherActor do
    use SpawnSdk.Actor,
      name: "second_actor",
      persistent: false,
      state_type: Eigr.Spawn.Actor.MyState,
      deactivate_timeout: 30_000,
      snapshot_timeout: 2_000

    alias Eigr.Spawn.Actor.MyMessageResponse

    defact caller_name(%Context{}) do
      %Value{}
      |> Value.value(nil)
      |> Value.pipe(Pipe.to("third_actor", "caller_name"))
      |> Value.void()
    end

    defact forward_caller_name(%Context{} = ctx) do
      %Value{}
      |> Value.value(MyMessageResponse.new(data: "second_caller"))
      |> Value.forward(Forward.to("third_actor", "forward_caller_name"))
      |> Value.void()
    end
  end

  defmodule Actor.ThirdActor do
    use SpawnSdk.Actor,
      name: "third_actor",
      persistent: false,
      state_type: Eigr.Spawn.Actor.MyState,
      deactivate_timeout: 30_000,
      snapshot_timeout: 2_000

    alias Eigr.Spawn.Actor.MyMessageResponse

    defact caller_name(%Context{} = ctx) do
      caller_name = "#{Map.get(ctx.caller || %{}, :name)} as caller to third_actor"

      %Value{}
      |> Value.value(MyMessageResponse.new(data: caller_name))
      |> Value.void()
    end

    defact forward_caller_name(value, %Context{} = ctx) do
      %Value{}
      |> Value.value(MyMessageResponse.new(id: value.data, data: "third forwarding"))
      |> Value.void()
    end
  end

  setup_all do
    system = "tst_syst"

    Supervisor.start_link(
      [
        {
          SpawnSdk.System.Supervisor,
          system: system, actors: [Actor.OtherActor, Actor.ThirdActor, Actor.MyActor]
        }
      ],
      strategy: :one_for_one,
      name: :random_ass_supervisor
    )

    %{system: system}
  end

  describe "meta/1" do
    test "assert meta fields" do
      assert Eigr.Spawn.Actor.MyState = Actor.MyActor.__meta__(:state_type)
    end

    test "get defaults" do
      assert true == Actor.MyActor.__meta__(:abstract)
      assert false == Actor.MyActor.__meta__(:persistent)
      assert 10_000 == Actor.MyActor.__meta__(:deactivate_timeout)
      assert 2_000 == Actor.MyActor.__meta__(:snapshot_timeout)
    end
  end

  describe "handle_command/2" do
    test "simple call for valid pattern match" do
      id = Faker.Superhero.name()
      data = Faker.StarWars.character()

      ctx = %SpawnSdk.Context{
        caller: nil,
        self: nil,
        state: Eigr.Spawn.Actor.MyState.new(id: "1", value: 1)
      }

      request = Eigr.Spawn.Actor.MyMessageRequest.new(id: id, data: data)
      Actor.MyActor.handle_command({"sum", request}, ctx)

      assert {:ok,
              %SpawnSdk.Value{
                state: %Eigr.Spawn.Actor.MyState{id: "1", value: 1},
                value: %Eigr.Spawn.Actor.MyMessageResponse{}
              }} = Actor.MyActor.handle_command({"sum", request}, ctx)
    end
  end

  describe "invoke with pipe" do
    test "simple call that goes through 3 actors piping each other", ctx do
      system = ctx.system

      payload = Eigr.Spawn.Actor.MyMessageRequest.new(data: "non_intended_data")

      dynamic_actor_name = Faker.Pokemon.name()

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: Actor.MyActor,
                 system: system,
                 command: "pipe_caller",
                 payload: payload
               )

      assert %{data: "second_actor as caller to third_actor"} = response
    end

    test "simple call that goes through 3 actors forwarding each other", ctx do
      system = ctx.system

      payload = Eigr.Spawn.Actor.MyMessageRequest.new(data: "initial_calling")

      dynamic_actor_name = Faker.Pokemon.name() <> "forward_caller"

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: Actor.MyActor,
                 system: system,
                 command: "forward_caller",
                 payload: payload
               )

      # keeps the original message request value even though values changed during forwarding (in id key)
      # gets the response value of the last forward (in data key)
      assert %Eigr.Spawn.Actor.MyMessageResponse{id: "initial_calling", data: "third forwarding"} =
               response
    end
  end
end
