defmodule Sidecar.ProcessSupervisor do
  @moduledoc false
  use Supervisor
  require Logger

  alias Actors.Config.PersistentTermConfig, as: Config

  alias Eigr.Functions.Protocol.Actors.Actor
  alias Eigr.Functions.Protocol.Actors.ActorId
  alias Eigr.Functions.Protocol.Actors.ActorDeactivationStrategy
  alias Eigr.Functions.Protocol.Actors.ActorSettings
  alias Eigr.Functions.Protocol.Actors.ActorSystem
  alias Eigr.Functions.Protocol.Actors.Metadata
  alias Eigr.Functions.Protocol.Actors.Registry
  alias Eigr.Functions.Protocol.Actors.TimeoutStrategy

  alias Eigr.Functions.Protocol.RegistrationRequest
  alias Eigr.Functions.Protocol.ServiceInfo

  import Spawn.Utils.Common, only: [supervisor_process_logger: 1]

  @impl true
  def init(opts) do
    children =
      [
        supervisor_process_logger(__MODULE__),
        {Sidecar.MetricsSupervisor, opts},
        Spawn.Supervisor.child_spec(opts),
        statestores(),
        Actors.Supervisors.ActorSupervisor.child_spec(opts),
        Actors.Supervisors.ProtocolSupervisor.child_spec(opts),
        %{
          id: :healthcheck_actor_init,
          start:
            {Task, :start,
             [
               fn ->
                 Process.flag(:trap_exit, true)

                 Logger.info("[SUPERVISOR] HealthCheckActor is up")

                 registration_internal_system = %RegistrationRequest{
                   service_info: %ServiceInfo{
                     service_name: "",
                     service_version: "",
                     service_runtime: "",
                     support_library_name: "",
                     support_library_version: ""
                   },
                   actor_system: %ActorSystem{
                     name: "#{Config.get(:actor_system_name)}-internal",
                     registry: %Registry{
                       actors: %{
                         "HealthCheckActor" => %Actor{
                           id: %ActorId{
                             system: "#{Config.get(:actor_system_name)}-internal",
                             name: "HealthCheckActor"
                           },
                           metadata: %Metadata{},
                           settings: %ActorSettings{
                             kind: :NAMED,
                             stateful: false,
                             deactivation_strategy: %ActorDeactivationStrategy{
                               strategy: {:timeout, %TimeoutStrategy{timeout: 120_000}}
                             }
                           }
                         }
                       }
                     }
                   }
                 }

                 Actors.register(registration_internal_system)

                 receive do
                   {:EXIT, _pid, reason} ->
                     Logger.info(
                       "[SUPERVISOR] HealthCheckActor:#{inspect(self())} is successfully down with reason #{inspect(reason)}"
                     )

                     :ok
                 end
               end
             ]}
        }
      ]
      |> Enum.reject(&is_nil/1)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(opts) do
    Supervisor.start_link(
      __MODULE__,
      opts,
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  if Code.ensure_loaded?(Statestores.Supervisor) do
    defp statestores, do: Statestores.Supervisor.child_spec()
  else
    defp statestores, do: nil
  end
end
