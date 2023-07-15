defmodule Spawn.Cluster.StateHandoff.Controllers.PersistentController do
  @moduledoc """
  `StateHandoffPersistentController` is a StateHandoff Controller basead on `Statestore` mechanism.
  """
  use Nebulex.Caching
  require Logger

  @behaviour Spawn.Cluster.StateHandoff.ControllerBehaviour

  alias Spawn.Cache.LookupCache, as: Cache

  @type node_type :: term()

  @type config :: map()

  @type data :: any()

  @type new_data :: data()

  @type id :: Eigr.Functions.Protocol.Actors.ActorId.t()

  @type host :: Actors.Registry.HostActor.t()

  @type hosts :: list(Actors.Registry.HostActor.t())

  @type timer :: {atom(), integer()}

  @otp_app :spawn

  @ttl :timer.minutes(10)

  @impl true
  @spec clean(node(), data()) :: data()
  def clean(node, data), do: handle_terminate(node, data)

  @impl true
  @spec get_by_id(id(), data()) :: {new_data(), hosts()}
  @decorate cacheable(cache: Cache, keys: [id], opts: [ttl: @ttl])
  def get_by_id(id, %{backend_adapter: backend} = data) do
    {:ok, lookups} = backend.get_by_id(id)

    hosts =
      Enum.map(lookups, fn data = _lookup ->
        :erlang.binary_to_term(data)
      end)

    {data, hosts}
  end

  @impl true
  @spec handle_init(config()) :: new_data() | {new_data(), timer()}
  def handle_init(_config) do
    backend = Application.get_env(@otp_app, :state_handoff_controller_persistent_backend)
    %{backend_adapter: backend}
  end

  @impl true
  @spec handle_after_init(data()) :: new_data()
  def handle_after_init(data), do: data

  @impl true
  @spec handle_terminate(node(), data()) :: new_data()
  @decorate cache_evict(cache: Cache, key: node)
  def handle_terminate(node, %{backend_adapter: backend} = data) do
    backend.clean(node)
    data
  end

  def handle_terminate(node, data) do
    Logger.warning("Invalid terminate state for Node #{inspect(node)}. State: #{inspect(data)}")
  end

  @impl true
  @spec handle_timer(any(), data()) :: new_data() | {new_data(), timer()}
  def handle_timer(_event, data), do: data

  @impl true
  @spec handle_nodeup_event(node(), node_type(), data()) :: new_data()
  def handle_nodeup_event(_node, _node_type, data), do: data

  @impl true
  @spec handle_nodedown_event(node(), node_type(), data()) :: new_data()
  def handle_nodedown_event(_node, _node_type, data), do: data

  @impl true
  @spec set(id(), node(), host(), data) :: new_data()
  def set(id, node, host, %{backend_adapter: backend} = data) do
    bytes = :erlang.term_to_binary(host)
    backend.set(id, node, bytes)
    data
  end
end
