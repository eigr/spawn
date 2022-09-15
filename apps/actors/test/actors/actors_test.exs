defmodule ActorsTest do
  use ExUnit.Case, async: false
  use Actors.MockTest
  import Actors.FactoryTest

  alias Eigr.Functions.Protocol.ActorInvocationResponse
  alias Eigr.Functions.Protocol.Actors.ActorState
  alias Eigr.Functions.Protocol.RegistrationResponse

  doctest Actors

  describe "register/1" do
    test "register actors for a system" do
      system = build_system_with_actors()
      request = build_registration_request(actor_system: system)

      assert {:ok, %RegistrationResponse{}} = Actors.register(request)
    end
  end

  describe "get_state/2" do
    test "get_state for a newly registered actor" do
      actor_name = "actor_test_" <> Ecto.UUID.generate()

      actor_entry = build_actor_entry(name: actor_name)
      registry = build_registry_with_actors(actors: [actor_entry])
      system = build_system(registry: registry)

      request = build_registration_request(actor_system: system)

      {:ok, %RegistrationResponse{}} = Actors.register(request)
      {:ok, %ActorState{state: %Google.Protobuf.Any{value: state}}} = Actors.get_state(system.name, actor_name)

      assert %Actors.Protos.StateTest{name: "example_state_name_" <> _rand} = Actors.Protos.StateTest.decode(state)
    end
  end

  describe "invoke/2" do
    test "invoke function for a newly registered actor" do
      actor_name = "actor_test_" <> Ecto.UUID.generate()

      actor = build_actor(name: actor_name)
      actor_entry = build_actor_entry(name: actor_name, actor: actor)
      registry = build_registry_with_actors(actors: [actor_entry])
      system = build_system(registry: registry)

      request = build_registration_request(actor_system: system)

      {:ok, %RegistrationResponse{}} = Actors.register(request)

      # invoke
      invoke_request = build_invocation_request(system: system, actor: actor)

      host_invoke_response = build_host_invoke_response(actor_name: actor_name, system_name: system.name)
      mock_invoke_host_actor_with_ok_response(host_invoke_response)

      assert {:ok, %ActorInvocationResponse{actor_name: ^actor_name}} = Actors.invoke(invoke_request)
    end
  end
end
