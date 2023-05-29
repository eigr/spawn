defmodule Actor.ActorTest do
  use ExUnit.Case

  defmodule Actor.MyActor do
    use SpawnSdk.Actor,
      kind: :abstract,
      stateful: false,
      state_type: Eigr.Spawn.Actor.MyState,
      tags: [{"foo", "none"}, {"bar", "unchanged"}]

    alias Eigr.Spawn.Actor.{MyMessageRequest, MyMessageResponse}

    defact init(%Context{} = ctx) do
      %Value{}
      |> Value.tags(Map.put(ctx.tags, "foo", "initial"))
      |> Value.void()
    end

    defact sum(%MyMessageRequest{id: id, data: data}, %Context{} = ctx) do
      current_state = ctx.state
      new_state = current_state

      response = %MyMessageResponse{id: id, data: data}
      result = %Value{state: new_state, value: response}

      {:ok, result}
    end

    defact change_tags(%Context{} = ctx) do
      %{"bar" => "unchanged"} = ctx.tags

      %Value{}
      |> Value.value(%MyMessageResponse{data: ctx.tags["foo"]})
      |> Value.tags(Map.put(ctx.tags, "foo", "changed"))
      |> Value.void()
    end

    defact pipe_caller(%MyMessageRequest{data: data}, %Context{} = _ctx) do
      %Value{}
      |> Value.value(%MyMessageResponse{data: data})
      |> Value.pipe(Pipe.to("second_actor", "caller_name"))
      |> Value.void()
    end

    defact forward_caller(%MyMessageRequest{data: _data}, %Context{} = _ctx) do
      %Value{}
      |> Value.value(%MyMessageResponse{data: "first_actor_value"})
      |> Value.forward(Forward.to("second_actor", "forward_caller_name"))
      |> Value.void()
    end

    defact use_side_effect(_ctx) do
      %Value{}
      |> Value.effects([
        SideEffect.to(
          "second_actor",
          "forward_caller_name",
          MyMessageResponse.new(data: "first_actor_value")
        )
      ])
      |> Value.value(%MyMessageResponse{data: "worked_with_effects"})
      |> Value.void()
    end

    defact wrong_state(_ctx) do
      Value.of()
      |> Value.state(%MyMessageResponse{data: "wrong"})
    end

    defact wrong_state_json(_ctx) do
      Value.of()
      |> Value.state(%{anything: "wrong"})
    end

    defact json_return(_ctx) do
      Value.of()
      |> Value.response(%{test: true})
    end
  end

  defmodule Actor.JsonActor do
    use SpawnSdk.Actor,
      kind: :abstract,
      stateful: false,
      state_type: :json

    defact init(_) do
      Value.noreply_state!(%{value: 0})
    end

    defact sum(%{value: new_value}, %Context{state: %{value: old_value}}) do
      total = old_value + new_value

      Value.of()
      |> Value.state(%{value: total})
      |> Value.response(%{value: total})
    end
  end

  defmodule Actor.PooledActor do
    use SpawnSdk.Actor,
      name: "pooledActor",
      kind: :pooled,
      stateful: false,
      min_pool_size: 10,
      max_pool_size: 15

    alias Eigr.Spawn.Actor.MyMessageResponse

    defact something(%Context{} = _ctx) do
      %Value{}
      |> Value.value(%MyMessageResponse{data: "something"})
      |> Value.void()
    end
  end

  defmodule Actor.OtherActor do
    use SpawnSdk.Actor,
      name: "second_actor",
      stateful: false,
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

    defact forward_caller_name(%Context{} = _ctx) do
      %Value{}
      |> Value.value(%MyMessageResponse{data: "second_caller"})
      |> Value.forward(Forward.to("third_actor", "forward_caller_name"))
      |> Value.void()
    end
  end

  defmodule Actor.ThirdActor do
    use SpawnSdk.Actor,
      name: "third_actor",
      stateful: false,
      state_type: Eigr.Spawn.Actor.MyState,
      deactivate_timeout: 30_000,
      snapshot_timeout: 2_000

    alias Eigr.Spawn.Actor.MyMessageResponse

    defact caller_name(%Context{} = ctx) do
      caller_name = "#{Map.get(ctx.caller || %{}, :name)} as caller to third_actor"

      Value.of()
      |> Value.response(%MyMessageResponse{data: caller_name})
    end

    defact forward_caller_name(value, %Context{} = _ctx) do
      %Value{}
      |> Value.value(%MyMessageResponse{id: value.data, data: "third forwarding"})
      |> Value.void()
    end
  end

  setup_all do
    system = "spawn-system"

    Supervisor.start_link(
      [
        {
          SpawnSdk.System.Supervisor,
          system: system,
          actors: [
            Actor.MyActor,
            Actor.OtherActor,
            Actor.ThirdActor,
            Actor.PooledActor,
            Actor.JsonActor
          ]
        }
      ],
      strategy: :one_for_one,
      name: :random_ass_supervisor
    )

    Process.sleep(200)
    %{system: system}
  end

  describe "meta/1" do
    test "assert meta fields" do
      assert Eigr.Spawn.Actor.MyState = Actor.MyActor.__meta__(:state_type)
    end

    test "get defaults" do
      assert :abstract == Actor.MyActor.__meta__(:kind)
      assert false == Actor.MyActor.__meta__(:stateful)
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
        state: %Eigr.Spawn.Actor.MyState{id: "1", value: 1}
      }

      request = %Eigr.Spawn.Actor.MyMessageRequest{id: id, data: data}
      Actor.MyActor.handle_command({"sum", request}, ctx)

      assert {:ok,
              %SpawnSdk.Value{
                state: %Eigr.Spawn.Actor.MyState{id: "1", value: 1},
                value: %Eigr.Spawn.Actor.MyMessageResponse{}
              }} = Actor.MyActor.handle_command({"sum", request}, ctx)
    end
  end

  describe "invoke json actor" do
    test "simple default function call returning only map without payload", ctx do
      system = ctx.system
      dynamic_actor_name = Faker.Pokemon.name() <> "json_actor_get_state"

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: Actor.JsonActor,
               command: "getState",
               system: system
             ) == {:ok, %{value: 0}}
    end

    test "simple call using maps with no proto", ctx do
      system = ctx.system
      dynamic_actor_name = Faker.Pokemon.name() <> "json_actor_call"

      payload = %{value: 2}

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: Actor.JsonActor,
               command: "sum",
               system: system,
               payload: payload
             ) == {:ok, %{value: 2}}
    end
  end

  describe "invoke with routing" do
    test "simple call that goes through 3 actors piping each other", ctx do
      system = ctx.system

      payload = %Eigr.Spawn.Actor.MyMessageRequest{data: "non_intended_data"}

      dynamic_actor_name = Faker.Pokemon.name() <> "piping"

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: Actor.MyActor,
                 system: system,
                 command: "pipe_caller",
                 payload: payload
               )

      assert %{data: "second_actor as caller to third_actor"} = response
    end

    test "calling a function that sets wrong state type", ctx do
      system = ctx.system
      dynamic_actor_name = Faker.Pokemon.name() <> "wrong_state"

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: Actor.MyActor,
               system: system,
               command: "wrong_state"
             ) == {:ok, nil}

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: Actor.MyActor,
               command: "getState",
               system: system
             ) == {:error, :invalid_state_output}
    end

    test "calling a function that sets wrong state type to json", ctx do
      system = ctx.system
      dynamic_actor_name = Faker.Pokemon.name() <> "wrong_state_json"

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: Actor.MyActor,
               system: system,
               command: "wrong_state_json"
             ) == {:ok, nil}

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: Actor.MyActor,
               system: system,
               command: "get_state"
             ) == {:ok, nil}
    end

    test "calling a function that returns json in response", ctx do
      system = ctx.system
      dynamic_actor_name = Faker.Pokemon.name() <> "json_return"

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: Actor.MyActor,
               system: system,
               command: "json_return"
             ) == {:ok, %{test: true}}
    end

    test "simple call that goes through 3 actors forwarding each other", ctx do
      system = ctx.system

      payload = %Eigr.Spawn.Actor.MyMessageRequest{data: "initial_calling"}

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

  describe "invoke with side effect" do
    test "simple call with a side effect", ctx do
      system = ctx.system

      payload = %Eigr.Spawn.Actor.MyMessageRequest{data: "non_intended_data"}

      dynamic_actor_name = Faker.Pokemon.name() <> "_side_effect"

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: Actor.MyActor,
                 system: system,
                 command: "use_side_effect",
                 payload: payload
               )

      assert %{data: "worked_with_effects"} = response
    end
  end

  describe "tags" do
    test "simple call verifying that tags is changed", ctx do
      system = ctx.system

      dynamic_actor_name = Faker.Pokemon.name() <> "_tags"

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: Actor.MyActor,
                 system: system,
                 command: "change_tags"
               )

      assert %{data: "initial"} = response

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: Actor.MyActor,
                 system: system,
                 command: "change_tags"
               )

      assert %{data: "changed"} = response
    end
  end

  describe "pooled" do
    test "simple call in pooled actor", ctx do
      system = ctx.system

      assert {:ok, response} =
               SpawnSdk.invoke("pooledActor",
                 system: system,
                 pooled: true,
                 command: "something"
               )

      assert %{data: "something"} = response
    end
  end
end
