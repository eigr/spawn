defmodule Spawn.Cluster.StateHandoff.Controllers.NatsKvController do
  @moduledoc """
  This handles state handoff in a cluster.

  It uses the Nats jetstream library to handle a distributed state, which is an eventually consistent replicated data type.
  """
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config

  import Spawn.Utils.Common, only: [generate_key: 1, actor_host_hash: 0]

  @behaviour Spawn.Cluster.StateHandoff.ControllerBehaviour

  @type node_type :: term()

  @type opts :: Keyword.t()

  @type data :: any()

  @type new_data :: data()

  @type id :: Eigr.Functions.Protocol.Actors.ActorId.t()

  @type host :: Actors.Registry.HostActor.t()

  @type hosts :: list(Actors.Registry.HostActor.t())

  @type timer :: {atom(), integer()}

  @doc """
  Cluster HostActor cleanup
  """
  @impl true
  def clean(node, %{} = data) do
    Logger.debug("Received cleanup action from Node #{inspect(node)}")

    system = Config.get(:actor_system_name)

    # hard fail in case of error
    :ok = Jetstream.API.KV.purge_key(conn(), bucket_name(), "#{system}.#{actor_host_hash()}.*")

    Logger.debug("Hosts cleaned for node #{inspect(node)}")

    data
  end

  @impl true
  @spec get_by_id(id(), data()) :: {new_data(), hosts()}
  def get_by_id(id, %{} = data) do
    key = generate_key(id)
    bucket_name = Jetstream.API.KV.stream_name(bucket_name())
    system = Config.get(:actor_system_name)

    hosts =
      case Jetstream.API.Stream.get_message(conn(), bucket_name, %{
             last_by_subj: "$KV.#{bucket_name()}.#{system}.#{actor_host_hash()}.#{key}"
           }) do
        {:ok, message} ->
          if is_nil(message.data) do
            []
          else
            host = :erlang.binary_to_term(message.data)

            # We claim the host if referenced node is down or unreachable
            # this will change the register reference but not persist it.
            # Later on the create_or_lookup_actor, it will try to find the active process
            # or create it in this new node.
            #
            # If somehow 2 actors are up at the same time, we have the
            # network partition mechanism to prevent it to cause inconsistent states
            if host.node not in (Node.list() ++ [Node.self()]) and
                 host.actor.id in :persistent_term.get(:local_requested_actors, []) do
              claimed_host = %{host | node: Node.self()}

              [claimed_host]
            else
              [host]
            end
          end

        _error ->
          []
      end

    {data, hosts}
  end

  @impl true
  @spec handle_init(opts()) :: new_data() | {new_data(), timer()}
  def handle_init(opts) do
    Jetstream.API.KV.create_bucket(conn(), bucket_name(), storage: :file)

    %{opts: opts}
  end

  @impl true
  @spec handle_after_init(data()) :: new_data()
  def handle_after_init(%{} = data) do
    data
  end

  @impl true
  @spec handle_terminate(node(), data()) :: new_data()
  def handle_terminate(_node, %{} = data) do
    data
  end

  def handle_terminate(node, data) do
    Logger.warning("Terminating #{inspect(__MODULE__)} #{inspect(node)}. State: #{inspect(data)}")
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
  def set(id, _node, host, %{} = data) do
    system = Config.get(:actor_system_name)
    key = generate_key(id)

    :ok =
      Jetstream.API.KV.put_value(
        conn(),
        bucket_name(),
        "#{system}.#{actor_host_hash()}.#{key}",
        :erlang.term_to_binary(host)
      )

    %{data | opts: host.opts}
  end

  defp conn, do: Spawn.Utils.Nats.connection_name()
  defp bucket_name, do: "spawn_hosts"
end
