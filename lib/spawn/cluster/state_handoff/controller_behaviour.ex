defmodule Spawn.Cluster.StateHandoff.ControllerBehaviour do
  @moduledoc """
  Behavior for managing the state of clustered processes a.k.a lookups.
  """
  @type node_type :: term()

  @type config :: map()

  @type data :: any()

  @type new_data :: data()

  @type id :: Eigr.Functions.Protocol.Actors.ActorId.t()

  @type host :: Actors.Registry.HostActor.t()

  @type hosts :: list(Actors.Registry.HostActor.t())

  @type timer :: {atom(), integer()}

  @doc """
  Cleanup action.
  """
  @callback clean(node(), data()) :: any()

  @doc """
  Fetch the ActorHost process reference by id.
  In case `id` is the hash of the ActorId but here the struct ActorId is passed as a parameter.
  An implementations must handle this.
  """
  @callback get_by_id(id(), data()) :: {new_data(), hosts()}

  @doc """
  Any initialization code required by implementations of this behavior.
  Must return the state to be added in the StateHandoffManager.
  """
  @callback handle_init(config()) :: new_data() | {new_data(), timer()}

  @doc """
  Any procedure to be executed after the StateHandoffManager is initialized.
  Executed during callback call to handle_continue.
  """
  @callback handle_after_init(data()) :: new_data()

  @doc """
  Perform any necessary cleanups during StateHandoffManager termination.
  Generally excluding references to all processes owned by the terminating node.
  """
  @callback handle_terminate(node(), data()) :: new_data()

  @callback handle_timer(any(), data()) :: new_data() | {new_data(), timer()}

  @doc """
  If necessary any procedure to be executed during a nodeup event
  """
  @callback handle_nodeup_event(node(), node_type(), data()) :: new_data()

  @doc """
  If necessary any procedure to be executed during a nodedown event
  """
  @callback handle_nodedown_event(node(), node_type(), data()) :: new_data()

  @doc """
  Adds a reference to an ActorHost process.
  """
  @callback set(id(), node(), host(), data) :: new_data()
end
