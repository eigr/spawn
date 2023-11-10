defmodule Actors.Supervisors.ActorSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  @shutdown_timeout_ms 330_000

  alias Actors.Actor.CallerProducer

  @base_app_dir File.cwd!()

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__, shutdown: @shutdown_timeout_ms)
  end

  def child_spec(config) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [config]}
    }
  end

  @impl true
  def init(config) do
    Protobuf.load_extensions()
    get_acl_manager().load_acl_policies("#{@base_app_dir}/policies")

    consumers =
      Enum.into(1..System.schedulers_online(), [], fn index ->
        %{
          id: index,
          start: {Actors.Actor.CallerConsumer, :start_link, [[id: index]]}
        }
      end)

    children =
      [
        get_pubsub_adapter(config),
        Actors.Actor.Entity.Supervisor.child_spec(config)
      ] ++
        maybe_add_invocation_scheduler(config) ++
        [{CallerProducer, []}] ++ consumers

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp get_acl_manager(),
    do: Application.get_env(:spawn, :acl_manager, Actors.Security.Acl.DefaultAclManager)

  defp maybe_add_invocation_scheduler(config) do
    if config.delayed_invokes == "true" do
      [{Highlander, Actors.Actor.InvocationScheduler.child_spec()}]
    else
      []
    end
  end

  defp get_pubsub_adapter(config) do
    case config.pubsub_adapter do
      "nats" ->
        {
          Phoenix.PubSub,
          name: :actor_channel,
          adapter: PhoenixPubsubNats,
          connection: Spawn.Utils.Nats.get_nats_connection(config)
        }

      _ ->
        {Phoenix.PubSub, name: :actor_channel}
    end
  end
end
