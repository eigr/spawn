defmodule Actors.Supervisors.ActorSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  @max_consumers 64
  @shutdown_timeout_ms 330_000

  alias Actors.Actor.CallerProducer
  alias Actors.Config.PersistentTermConfig, as: Config

  @base_app_dir File.cwd!()

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__, shutdown: @shutdown_timeout_ms)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def init(opts) do
    Protobuf.load_extensions()
    get_acl_manager().load_acl_policies("#{@base_app_dir}/policies")

    consumers =
      Enum.into(1..@max_consumers, [], fn index ->
        %{
          id: index,
          start: {Actors.Actor.CallerConsumer, :start_link, [[id: index, opts: opts]]}
        }
      end)

    children =
      [
        get_pubsub_adapter(opts),
        Actors.Actor.Pubsub,
        Actors.Actor.Entity.Supervisor.child_spec(opts)
      ] ++
        maybe_add_invocation_scheduler(opts) ++
        [{CallerProducer, []}] ++ consumers

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_acl_manager(),
    do: Application.get_env(:spawn, :acl_manager, Actors.Security.Acl.DefaultAclManager)

  defp maybe_add_invocation_scheduler(_opts) do
    if Config.get(:delayed_invokes) do
      [{Highlander, Actors.Actor.InvocationScheduler.child_spec()}]
    else
      []
    end
  end

  defp get_pubsub_adapter(opts) do
    case Config.get(:pubsub_adapter) do
      "nats" ->
        {
          Phoenix.PubSub,
          name: :actor_channel,
          adapter: PhoenixPubsubNats,
          connection: Spawn.Utils.Nats.get_nats_connection(opts)
        }

      _ ->
        {Phoenix.PubSub, name: :actor_channel}
    end
  end
end
