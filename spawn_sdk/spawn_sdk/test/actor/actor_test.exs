defmodule Actor.ActorTest do
  use ExUnit.Case

  require Logger

  alias Eigr.Spawn.Actor.{MyMessageRequest, MyMessageResponse}

  defmodule Actor.TaskActor do
    use SpawnSdk.Actor,
      name: "task_actor_ref",
      kind: :task,
      stateful: true,
      state_type: Eigr.Spawn.Actor.MyState,
      tags: [{"foo", "none"}, {"bar", "unchanged"}]

    defact init(_) do
      Value.noreply_state!(%Eigr.Spawn.Actor.MyState{value: 0})
    end

    action("Sum", fn %Context{} = ctx, %MyMessageRequest{} = payload ->
      Value.of()
      |> Value.response(payload)
      |> Value.state(%Eigr.Spawn.Actor.MyState{ctx.state | value: 999})
    end)
  end

  defmodule Actor.MyActor do
    use SpawnSdk.Actor,
      name: "my_actor_ref",
      kind: :unnamed,
      stateful: false,
      state_type: Eigr.Spawn.Actor.MyState,
      tags: [{"foo", "none"}, {"bar", "unchanged"}]

    alias Eigr.Spawn.Actor.{MyMessageRequest, MyMessageResponse}

    init(fn %Context{} = ctx ->
      %Value{}
      |> Value.tags(Map.put(ctx.tags, "foo", "initial"))
      |> Value.void()
    end)

    action("test_error", fn _ctx, _payload ->
      # match error
      1 = 2

      Value.of()
    end)

    action("sum", fn %Context{} = ctx, %MyMessageRequest{id: id, data: data} ->
      current_state = ctx.state
      new_state = current_state

      response = %MyMessageResponse{id: id, data: data}
      result = %Value{state: new_state, value: response}

      result
      |> Value.noreply!()
    end)

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
          %MyMessageResponse{data: "first_actor_value"},
          nil,
          metadata: %{"some_meta" => "meta_present"}
        )
      ])
      |> Value.response(%MyMessageResponse{data: "worked_with_effects"})
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
      name: "json_actor_ref",
      kind: :abstract,
      stateful: false,
      state_type: :json

    init(fn _ctx ->
      Value.noreply_state!(%{value: 0})
    end)

    defact sum(%{value: new_value}, %Context{state: %{value: old_value}}) do
      total = old_value + new_value

      Value.of()
      |> Value.state(%{value: total})
      |> Value.response(%{value: total})
    end
  end

  defmodule Actor.TimerActor do
    use SpawnSdk.Actor,
      name: "timer_actor_ref",
      kind: :abstract,
      stateful: true,
      state_type: :json

    defact init(_) do
      Value.noreply_state!(%{value: 0})
    end

    @set_timer 5
    defact plus_one(%Context{state: %{value: old_value}}) do
      total = old_value + 1

      Value.of()
      |> Value.state(%{value: total})
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
      |> Value.response(%MyMessageResponse{
        data: caller_name <> " " <> Map.get(ctx.metadata, "origin_meta")
      })
    end

    defact forward_caller_name(value, %Context{} = _ctx) do
      %Value{}
      |> Value.value(%MyMessageResponse{id: value.data, data: "third forwarding"})
      |> Value.void()
    end
  end

  defmodule Actor.BroadcastActor do
    use SpawnSdk.Actor,
      name: "broadcastActor",
      stateful: true,
      state_type: Eigr.Spawn.Actor.MyState,
      channels: ["topics"],
      deactivate_timeout: 30_000,
      snapshot_timeout: 2_000

    action("publish", fn %Context{}, request ->
      Value.of()
      |> Value.broadcast(Broadcast.to("topics", request))
    end)

    action("receive", &receive_handler/2)

    defp receive_handler(%Context{}, request) do
      %Value{}
      |> Value.state(%Eigr.Spawn.Actor.MyState{id: request.data})
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
            Actor.JsonActor,
            Actor.BroadcastActor,
            Actor.TaskActor,
            Actor.TimerActor
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
      assert :UNNAMED == Actor.MyActor.__meta__(:kind)
      assert false == Actor.MyActor.__meta__(:stateful)
      assert 10_000 == Actor.MyActor.__meta__(:deactivate_timeout)
      assert 2_000 == Actor.MyActor.__meta__(:snapshot_timeout)
    end
  end

  describe "handle_action/2" do
    test "simple call for valid pattern match" do
      id = "#{inspect(make_ref())}"
      data = "#{inspect(make_ref())}"

      ctx = %SpawnSdk.Context{
        caller: nil,
        self: nil,
        state: %Eigr.Spawn.Actor.MyState{id: "1", value: 1}
      }

      request = %Eigr.Spawn.Actor.MyMessageRequest{id: id, data: data}
      Actor.MyActor.handle_action({"sum", request}, ctx)

      assert %SpawnSdk.Value{
               state: %Eigr.Spawn.Actor.MyState{id: "1", value: 1},
               value: %Eigr.Spawn.Actor.MyMessageResponse{}
             } = Actor.MyActor.handle_action({"sum", request}, ctx)
    end
  end

  describe "invoke task actors" do
    test "simple invoke task actor", ctx do
      system = ctx.system
      actor_name = "task_actor_ref"

      SpawnSdk.invoke(actor_name,
        action: "Sum",
        system: system,
        payload: %MyMessageRequest{id: "abc", data: "999"}
      )

      assert {:ok, %Eigr.Spawn.Actor.MyState{value: 999}} =
               SpawnSdk.invoke(actor_name,
                 action: "GetState",
                 system: system
               )
    end
  end

  describe "invoke json actor" do
    test "simple default function call returning only map without payload", ctx do
      system = ctx.system
      dynamic_actor_name = "#{inspect(make_ref())}" <> "json_actor_get_state"

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: "json_actor_ref",
               action: "getState",
               system: system
             ) == {:ok, %{value: 0}}
    end

    test "simple delay invoke changing state", ctx do
      system = ctx.system
      dynamic_actor_name = "#{inspect(make_ref())}" <> "json_actor_delay_change_state"

      SpawnSdk.invoke(dynamic_actor_name,
        ref: "json_actor_ref",
        action: "sum",
        system: system,
        payload: %{value: 999},
        delay: 5
      )

      Process.sleep(100)

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: "json_actor_ref",
               action: "getState",
               system: system
             ) == {:ok, %{value: 999}}
    end

    test "simple scheduled_at invoke changing state", ctx do
      system = ctx.system
      dynamic_actor_name = "#{inspect(make_ref())}" <> "json_actor_scheduled_change_state"

      SpawnSdk.invoke(dynamic_actor_name,
        ref: "json_actor_ref",
        action: "sum",
        system: system,
        payload: %{value: 99},
        scheduled_at: DateTime.utc_now() |> DateTime.add(5, :second)
      )

      Process.sleep(100)

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: "json_actor_ref",
               action: "getState",
               system: system
             ) == {:ok, %{value: 99}}
    end

    test "simple call using maps with no proto", ctx do
      system = ctx.system
      dynamic_actor_name = "#{inspect(make_ref())}" <> "json_actor_call"

      payload = %{value: 2}

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: "json_actor_ref",
               action: "sum",
               system: system,
               payload: payload
             ) == {:ok, %{value: 2}}
    end
  end

  describe "invoke timer actor" do
    test "simple state check", ctx do
      system = ctx.system

      dynamic_actor_name =
        "#{inspect(make_ref())}" <> "#{Ecto.UUID.generate()}_timer_actor_ref_new"

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: "timer_actor_ref",
               action: "getState",
               system: system
             ) == {:ok, %{value: 0}}

      Process.sleep(20)

      assert {:ok, %{value: value}} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: "timer_actor_ref",
                 action: "getState",
                 system: system
               )

      assert value > 1
    end
  end

  describe "invoke with routing" do
    test "simple exception error inside an action", ctx do
      system = ctx.system

      dynamic_actor_name = "#{inspect(make_ref())}" <> "simple_error"

      assert {:error, _response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: "my_actor_ref",
                 system: system,
                 action: "test_error"
               )
    end

    test "simple call that goes through 3 actors piping each other", ctx do
      system = ctx.system

      payload = %Eigr.Spawn.Actor.MyMessageRequest{data: "non_intended_data"}

      dynamic_actor_name = "#{inspect(make_ref())}" <> "piping"

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: "my_actor_ref",
                 system: system,
                 action: "pipe_caller",
                 payload: payload,
                 metadata: %{"origin_meta" => "meta_present"}
               )

      assert %{data: "second_actor as caller to third_actor meta_present"} = response
    end

    test "calling a function that sets wrong state type", ctx do
      system = ctx.system
      dynamic_actor_name = "#{inspect(make_ref())}" <> "wrong_state"

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: "my_actor_ref",
               system: system,
               action: "wrong_state"
             ) == {:ok, nil}

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: "my_actor_ref",
               action: "getState",
               system: system
             ) == {:error, :invalid_state_output}
    end

    test "calling a function that sets wrong state type to json", ctx do
      system = ctx.system
      dynamic_actor_name = "#{inspect(make_ref())}" <> "wrong_state_json"

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: "my_actor_ref",
               system: system,
               action: "wrong_state_json"
             ) == {:ok, nil}

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: "my_actor_ref",
               system: system,
               action: "get_state"
             ) == {:ok, nil}
    end

    test "calling a function that returns json in response", ctx do
      system = ctx.system
      dynamic_actor_name = "#{inspect(make_ref())}" <> "json_return"

      assert SpawnSdk.invoke(dynamic_actor_name,
               ref: "my_actor_ref",
               system: system,
               action: "json_return"
             ) == {:ok, %{test: true}}
    end

    test "simple call that goes through 3 actors forwarding each other", ctx do
      system = ctx.system

      payload = %Eigr.Spawn.Actor.MyMessageRequest{data: "initial_calling"}

      dynamic_actor_name = "#{inspect(make_ref())}" <> "forward_caller"

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: "my_actor_ref",
                 system: system,
                 action: "forward_caller",
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

      dynamic_actor_name = "#{inspect(make_ref())}" <> "_side_effect"

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: "my_actor_ref",
                 system: system,
                 action: "use_side_effect",
                 payload: payload
               )

      assert %{data: "worked_with_effects"} = response
    end
  end

  describe "tags" do
    test "simple call verifying that tags is changed", ctx do
      system = ctx.system

      dynamic_actor_name = "#{inspect(make_ref())}" <> "_tags"

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: "my_actor_ref",
                 system: system,
                 action: "change_tags"
               )

      assert %{data: "initial"} = response

      assert {:ok, response} =
               SpawnSdk.invoke(dynamic_actor_name,
                 ref: "my_actor_ref",
                 system: system,
                 action: "change_tags"
               )

      assert %{data: "changed"} = response
    end
  end

  describe "pooled" do
    @tag :skip
    test "simple call in pooled actor", ctx do
      system = ctx.system

      assert {:ok, response} =
               SpawnSdk.invoke("pooledActor",
                 system: system,
                 pooled: true,
                 action: "something"
               )

      assert %{data: "something"} = response
    end
  end

  describe "broadcast" do
    test "invoke broadcasting a simple state", ctx do
      system = ctx.system

      fake_payload_data = "#{inspect(make_ref())}" <> "_fake_payload"
      payload = %Eigr.Spawn.Actor.MyMessageRequest{data: fake_payload_data}

      assert {:ok, _} =
               SpawnSdk.invoke("broadcastActor",
                 system: system,
                 payload: payload,
                 action: "publish"
               )

      Process.sleep(100)

      assert {:ok, %{id: ^fake_payload_data}} =
               SpawnSdk.invoke("broadcastActor",
                 system: system,
                 action: "get"
               )
    end
  end

  describe "parallel" do
    @tag timeout: :infinity
    @tag parallel: true
    @tag :skip
    test "simple call that goes through 3 actors piping each other heavily", ctx do
      system = ctx.system

      1..10_000
      |> Task.async_stream(
        fn number ->
          number
        end,
        max_concurrency: 100,
        timeout: :infinity
      )
      |> Stream.map(fn {:ok, number} ->
        payload = %Eigr.Spawn.Actor.MyMessageRequest{data: "#{number}"}

        dynamic_actor_name = "#{inspect(make_ref())}-piping-#{number}"

        # assert {:ok, :async} =
        #          SpawnSdk.invoke(dynamic_actor_name,
        #            async: true,
        #            ref: "my_actor_ref",
        #            system: system,
        #            action: "pipe_caller",
        #            payload: payload
        #          )

        assert {:ok, response} =
                 SpawnSdk.invoke(dynamic_actor_name,
                   ref: "my_actor_ref",
                   system: system,
                   action: "pipe_caller",
                   payload: payload
                 )

        assert %{data: "second_actor as caller to third_actor"} = response
      end)
      |> Enum.to_list()
    end
  end
end
