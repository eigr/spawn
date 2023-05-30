defmodule Spawn.StateHandoff.Controller.Behaviour do
  @moduledoc """

  """
  @type node_type :: term()

  @type config :: map()

  @type data :: any()

  @type new_data :: data()

  @type id :: Eigr.Functions.Protocol.Actors.ActorId.t()

  @type host :: Actors.Registry.HostActor.t()

  @type hosts :: list(Actors.Registry.HostActor.t())

  @callback get_by_id(id(), node(), data()) :: {new_data(), hosts()}

  @callback handle_init(config()) :: new_data()

  @callback handle_after_nit(data()) :: new_data()

  @callback handle_terminate(node(), data()) :: new_data()

  @callback handle_nodeup_event(node(), node_type(), data()) :: new_data()

  @callback handle_nodedown_event(node(), node_type(), data()) :: new_data()

  @callback set(id(), node(), host(), data) :: new_data()
end
