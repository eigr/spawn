defmodule Actors.AclEvaluatorTest do
  use ExUnit.Case, async: true
  doctest Actors.Security.Acl.Rules.AclEvaluator

  alias Actors.Security.Acl.Rules.AclEvaluator
  alias Actors.Security.Acl.Policy

  alias Eigr.Functions.Protocol.InvocationRequest

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId
  }

  setup do
    default = %Policy{
      name: "default",
      type: :allow,
      actors: ["*"],
      actions: ["*"],
      actor_systems: ["*"]
    }

    deny_all = %Policy{
      name: "default",
      type: :deny,
      actors: ["*"],
      actions: ["*"],
      actor_systems: ["*"]
    }

    robert_policy = %Policy{
      name: "robert",
      type: :allow,
      actors: ["robert"],
      actions: ["*"],
      actor_systems: ["*"]
    }

    deny_robert_policy = %Policy{
      name: "deny-robert",
      type: :deny,
      actors: ["robert"],
      actions: ["*"],
      actor_systems: ["*"]
    }

    simple_invocation = %InvocationRequest{
      actor: %Actor{id: %ActorId{name: "joe"}},
      command_name: "get",
      caller: %ActorId{name: "caller_actor_name", system: "actor_system"}
    }

    specific_actor_invocation = %InvocationRequest{
      actor: %Actor{id: %ActorId{name: "joe"}},
      command_name: "get",
      caller: %ActorId{name: "robert", system: "actor_system"}
    }

    outsider_invocation = %InvocationRequest{
      actor: %Actor{id: %ActorId{name: "joe"}},
      command_name: "get",
      caller: %ActorId{name: "mike", system: "actor_system"}
    }

    %{
      default_all_policy: default,
      deny_all_policy: deny_all,
      specific_actor_policy: robert_policy,
      deny_specific_actor_policy: deny_robert_policy,
      simple_invocation: simple_invocation,
      outsider_invocation: outsider_invocation,
      specific_actor_invocation: specific_actor_invocation
    }
  end

  describe "apply default policy rules" do
    test "matching default allow policy", %{
      default_all_policy: policy,
      simple_invocation: invocation
    } do
      assert AclEvaluator.eval(policy, invocation) == true
    end

    test "matching default deny policy", %{deny_all_policy: policy, simple_invocation: invocation} do
      assert AclEvaluator.eval(policy, invocation) == false
    end
  end

  describe "more complex policy rules" do
    test "accept specific actor invocation", %{
      specific_actor_policy: policy,
      specific_actor_invocation: invocation
    } do
      assert AclEvaluator.eval(policy, invocation) == true
    end

    test "reject ousider invocations", %{
      specific_actor_policy: policy,
      outsider_invocation: invocation
    } do
      assert AclEvaluator.eval(policy, invocation) == false
    end

    test "reject specific actor", %{
      deny_specific_actor_policy: policy,
      specific_actor_invocation: invocation
    } do
      assert AclEvaluator.eval(policy, invocation) == false
    end
  end

  describe "action policy rules" do
    test "accept all actor invocation if action are get" do
      policy = %Policy{
        name: "the-police",
        type: :allow,
        actors: ["*"],
        actions: ["get"],
        actor_systems: ["*"]
      }

      invocation = %InvocationRequest{
        actor: %Actor{id: %ActorId{name: "joe"}},
        command_name: "get",
        caller: %ActorId{name: "caller_actor_name", system: "actor_system"}
      }

      assert AclEvaluator.eval(policy, invocation) == true
    end

    test "reject all actor invocation if action are get" do
      policy = %Policy{
        name: "the-police",
        type: :deny,
        actors: ["*"],
        actions: ["get"],
        actor_systems: ["*"]
      }

      invocation = %InvocationRequest{
        actor: %Actor{id: %ActorId{name: "joe"}},
        command_name: "get",
        caller: %ActorId{name: "caller_actor_name", system: "actor_system"}
      }

      assert AclEvaluator.eval(policy, invocation) == false
    end

    test "reject all actor invocation if action are different get" do
      policy = %Policy{
        name: "the-police",
        type: :allow,
        actors: ["*"],
        actions: ["get"],
        actor_systems: ["*"]
      }

      invocation = %InvocationRequest{
        actor: %Actor{id: %ActorId{name: "joe"}},
        command_name: "sum",
        caller: %ActorId{name: "caller_actor_name", system: "actor_system"}
      }

      assert AclEvaluator.eval(policy, invocation) == false
    end
  end
end
