defmodule Actors.Security.Acl.Rules.AclEvaluator do
  @moduledoc """
  `AclEvaluator`is responsible for evaluating whether a request can be accepted
  or not based on the informed Access Control List policy.
  """
  alias Actors.Security.Acl.Policy

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId
  }

  alias Eigr.Functions.Protocol.InvocationRequest

  @doc """
  Applies a policy on a request by evaluating whether the request should pass or not.

  ## Example

      iex> Actors.Security.Acl.Rules.AclEvaluator.eval(
      ...> %Actors.Security.Acl.Policy{
      ...>   name: "the-police",
      ...>   type: :allow,
      ...>   actors: ["*"],
      ...>   actions: ["get"],
      ...>   actor_systems: ["*"]
      ...> },
      ...> %Eigr.Functions.Protocol.InvocationRequest{
      ...>    actor: %Eigr.Functions.Protocol.Actors.Actor{id: %Eigr.Functions.Protocol.Actors.ActorId{name: "joe"}},
      ...>    action_name: "get",
      ...>    caller: %Eigr.Functions.Protocol.Actors.ActorId{name: "robert", system: "actor-system"}
      ...> }
      ...> )
      true
  """
  @spec eval(Policy.t(), InvocationRequest.t(), Keyword.t()) :: boolean()
  def eval(policy, invocation, opts \\ [])

  def eval(
        %Policy{
          name: name,
          type: type,
          actors: actors,
          actions: actions,
          actor_systems: actor_systems
        },
        invocation,
        opts
      ) do
    actors = normalize_list_input(actors)
    actions = normalize_list_input(actions)
    actor_systems = normalize_list_input(actor_systems)

    eval_options = [name: name, invocation: invocation]
    opts = Keyword.merge(opts, eval_options)

    do_evaluation(type, actor_systems, actors, actions, opts)
  end

  defp do_evaluation(type, :all, :all, :all, _opts) when is_atom(type) and type == :allow,
    do: true

  defp do_evaluation(type, :all, :all, :all, _opts) when is_atom(type) and type == :deny,
    do: false

  defp do_evaluation(type, actor_systems, actors, actions, opts) do
    %InvocationRequest{
      actor: %Actor{} = _actor,
      caller: %ActorId{name: from_actor_name, system: from_system},
      action_name: action
    } = _invocation = Keyword.get(opts, :invocation)

    has_system? = match_op?(actor_systems, from_system)
    has_actor_name? = match_op?(actors, from_actor_name)
    has_action? = match_op?(actions, action)

    case type do
      :allow ->
        has_system? && has_actor_name? && has_action?

      :deny ->
        !(has_system? && has_actor_name? && has_action?)
    end
  end

  defp match_op?(:all, _elem), do: true

  defp match_op?(list, elem), do: Enum.member?(list, elem)

  defp normalize_list_input(list) do
    if Enum.member?(list, "*") do
      :all
    else
      list
    end
  end
end
