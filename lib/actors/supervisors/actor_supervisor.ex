defmodule Actors.Supervisors.ActorSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  @base_app_dir File.cwd!()

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
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
      Enum.into(1..(System.schedulers_online() * 2), [], fn index ->
        %{
          id: index,
          start:
            {Actors.Actor.ActorSynchronousCallerConsumer, :start_link,
             [[id: index, min_demand: 50, max_demand: 100]]}
        }
      end)

    children =
      [
        get_pubsub_adapter(config),
        Actors.Actor.Entity.Supervisor.child_spec(config)
      ] ++
        maybe_add_invocation_scheduler(config) ++
        [{Actors.Actor.ActorSynchronousCallerProducer, []}] ++ consumers

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
