defmodule Actors.Security.Acl.Rules.AclEvaluator do
  @moduledoc """
  `AclEvaluator`is responsible for evaluating whether a request can be accepted
  or not based on the informed Access Control List policy.
  """
  alias Actors.Security.Acl.Policy

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
    true

    eval_options = [name: name, invocation: invocation]
    opts = Keyword.merge(opts, eval_options)

    do_evaluation(type, actor_systems, actors, actions, opts)
  end

  defp do_evaluation(type, :all, :all, :all, _opts) when is_atom(type) and type == :allow,
    do: true

  defp do_evaluation(type, :all, :all, :all, _opts) when is_atom(type) and type == :deny,
    do: false

  defp do_evaluation(type, actor_systems, actors, actions, opts) do
    invocation = Keyword.get(opts, :invocation)
  end

  defp normalize_list_input(list) do
    if Enum.member?(list, "*") do
      :all
    else
      list
    end
  end
end
