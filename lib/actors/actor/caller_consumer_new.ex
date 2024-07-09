defmodule Actors.Actor.CallerConsumerNew do
  @moduledoc """
  An Elixir module representing a GenStage consumer responsible for handling
  events initiated by `CallerProducer` and interacting with actors in the system.
  """
  use GenStage
  use Retry

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias Actors.Actor.CallerProducer
  alias Actors.Config.PersistentTermConfig, as: Config
  alias Actors.Actor.Entity, as: ActorEntity
  alias Actors.Actor.Entity.Supervisor, as: ActorEntitySupervisor
  alias Actors.Actor.InvocationScheduler

  alias Eigr.Functions.Protocol.Actors.{
    Actor,
    ActorId,
    ActorSystem,
    Registry
  }

  alias Eigr.Functions.Protocol.{
    InvocationRequest,
    ProxyInfo,
    RegistrationRequest,
    RegistrationResponse,
    RequestStatus,
    ServiceInfo,
    SpawnRequest,
    SpawnResponse
  }

  alias Spawn.Cluster.Node.Distributor

  alias Sidecar.Measurements

  import Spawn.Utils.Common, only: [to_existing_atom_or_new: 1]

  @activate_actors_min_demand 0
  @activate_actors_max_demand 4

  @erpc_timeout 5_000

  @doc """
  Registers actors in the system based on the provided registration request.

  Handles registration requests and ensures actors are properly registered.
  """
  def register(
        %RegistrationRequest{
          service_info: %ServiceInfo{} = _service_info,
          actor_system:
            %ActorSystem{name: name, registry: %Registry{actors: actors} = _registry} =
              actor_system
        } = _registration,
        _opts
      ) do
    size = length(actors)
    Logger.info("Registering #{inspect(size)} Actors on ActorSystem #{name}")

    if Sidecar.GracefulShutdown.running?() do
      case Distributor.register(actor_system) do
        :ok ->
          status = %RequestStatus{status: :OK, message: "Accepted"}
          {:ok, %RegistrationResponse{proxy_info: get_proxy_info(), status: status}}

        _ ->
          status = %RequestStatus{
            status: :ERROR,
            message: "Failed to register one or more Actors"
          }

          {:error, %RegistrationResponse{proxy_info: get_proxy_info(), status: status}}
      end
    else
      status = %RequestStatus{
        status: :ERROR,
        message: "You can't register actors when node is stopping"
      }

      {:error, %RegistrationResponse{proxy_info: get_proxy_info(), status: status}}
    end
  end

  @doc """
  Gets the state of the specified actor.

  This function attempts to retrieve the state of the actor identified by the given
  `ActorId`. It uses an exponential backoff strategy for retrying in case of errors
  and logs any failures.

  ## Parameters

  - `id` (%ActorId): The unique identifier of the actor.

  ## Returns

  The state of the actor if successful, otherwise an error is raised.

  ## Retry Strategy

  The function utilizes an exponential backoff strategy with randomized delays and
  a maximum expiry time of 30,000 milliseconds.

  ## Errors

  The function handles errors such as `:error`, `:exit`, `:noproc`, `:erpc`,
  `:noconnection`, and `:timeout`. It also rescues `ErlangError` exceptions and logs
  detailed error messages.

  """
  def get_state(%ActorId{name: actor_name, system: system_name} = id) do
  end

  @doc """
  Performs a readiness check for a given actor identified by `%ActorId{}`.

  This function uses a retry mechanism with exponential backoff, randomization, and a 30-second expiry to handle errors and failures gracefully.
  It attempts to check the readiness of the specified actor, logging any errors encountered during the process.

  ## Parameters

    - `id`: An `%ActorId{}` struct that contains:
      - `name`: The name of the actor.
      - `system`: The name of the system the actor belongs to.

  ## Returns

    - `{:ok, %HealthCheckReply{}}` if the readiness check is successful. The `HealthCheckReply` struct contains:
      - `status`: A `HealthcheckStatus` struct with:
        - `status`: A string indicating the status, e.g., "OK".
        - `details`: A string providing additional details, e.g., "I'm alive!".
        - `updated_at`: A `Google.Protobuf.Timestamp` indicating the last update time.
    - An error tuple (e.g., `{:error, :noproc}`) if the readiness check fails after all retry attempts.

  ## Examples

      iex> readiness(%ActorId{name: "actor1", system: "system1"})
      {:ok,
        %HealthCheckReply{
          status: %HealthcheckStatus{
            status: "OK",
            details: "I'm alive!",
            updated_at: %Google.Protobuf.Timestamp{seconds: 1717606730}
          }
        }}

      iex> readiness(%ActorId{name: "nonexistent_actor", system: "system1"})
      {:error, :noproc}

  ## Notes

  The retry mechanism handles the following cases: `:error`, `:exit`, `:noproc`, `:erpc`, `:noconnection`, and `:timeout`. It rescues only `ErlangError`.

  The readiness check is performed by calling `ActorEntity.readiness/2` on the actor reference obtained through `do_lookup_action/4`.

  Any errors during the readiness check are logged with a message indicating the actor's name and the error encountered.
  """
  @spec readiness(ActorId.t()) :: {:ok, HealthCheckReply.t()} | {:error, any()}
  def readiness(%ActorId{name: actor_name, system: system_name} = id) do
  end

  @doc """
  Performs a liveness check for a given actor identified by `%ActorId{}`.

  This function uses a retry mechanism with exponential backoff, randomization, and a 30-second expiry to handle errors and failures gracefully.
  It attempts to check the liveness of the specified actor, logging any errors encountered during the process.

  ## Parameters

    - `id`: An `%ActorId{}` struct that contains:
      - `name`: The name of the actor.
      - `system`: The name of the system the actor belongs to.

  ## Returns

    - `{:ok, %HealthCheckReply{}}` if the liveness check is successful. The `HealthCheckReply` struct contains:
      - `status`: A `HealthcheckStatus` struct with:
        - `status`: A string indicating the status, e.g., "OK".
        - `details`: A string providing additional details, e.g., "I'm alive!".
        - `updated_at`: A `Google.Protobuf.Timestamp` indicating the last update time.
    - An error tuple (e.g., `{:error, :noproc}`) if the liveness check fails after all retry attempts.

  ## Examples

      iex> liveness(%ActorId{name: "actor1", system: "system1"})
      {:ok,
        %HealthCheckReply{
          status: %HealthcheckStatus{
            status: "OK",
            details: "I'm still alive!",
            updated_at: %Google.Protobuf.Timestamp{seconds: 1717606837}
          }
        }}

      iex> liveness(%ActorId{name: "nonexistent_actor", system: "system1"})
      {:error, :noproc}

  ## Notes

  The retry mechanism handles the following cases: `:error`, `:exit`, `:noproc`, `:erpc`, `:noconnection`, and `:timeout`. It rescues only `ErlangError`.

  The liveness check is performed by calling `ActorEntity.liveness/2` on the actor reference obtained through `do_lookup_action/4`.

  Any errors during the liveness check are logged with a message indicating the actor's name and the error encountered.
  """
  @spec liveness(ActorId.t()) :: {:ok, HealthCheckReply.t()} | {:error, any()}
  def liveness(%ActorId{name: actor_name, system: system_name} = id) do
  end

  @doc """
  Spawns an actor or a group of actors based on the provided `SpawnRequest`.

  This function is responsible for spawning actors based on the specified `SpawnRequest`.
  It retrieves the hosts associated with the provided actor IDs and registers the actors.
  Additionally, it handles cases where the system is in the process of draining or stopping.

  ## Parameters

  - `spawn` (%SpawnRequest): The request containing information about the actors to spawn.
  - `opts` (Keyword.t): Additional options for spawning the actors. Defaults to an empty keyword list.

  ## Returns

  If successful, it returns `{:ok, %SpawnResponse{status: %RequestStatus{status: :OK, message: "Accepted"}}}`.
  Otherwise, an error is raised.

  ## Actor Spawning Process

  - Retrieves actor hosts based on actor IDs from the `ActorRegistry`.
  - Filters the hosts based on the system's graceful shutdown status.
  - Registers the selected hosts in the `ActorRegistry`.
  - Returns a success response.

  ## Errors

  - Raises an `ArgumentError` if attempting to spawn an unnamed actor that has not been registered before.

  """
  def spawn_actor(spawn, opts \\ [])

  def spawn_actor(%SpawnRequest{actors: actors} = _spawn, opts) do
  end

  @doc """
  Invokes an actor action with distributed tracing using OpenTelemetry.

  This function performs an actor action invocation, incorporating distributed tracing
  with OpenTelemetry. It sets up the tracing context, adds relevant attributes,
  and handles asynchronous and synchronous invocations.

  ## Parameters

  - `request` (%InvocationRequest): The request containing information about the invocation.
  - `opts` (Keyword.t): Additional options for the invocation. Defaults to an empty keyword list.

  ## Returns

  A tuple containing the status and the result of the invocation.
  If the invocation is asynchronous, it returns `{:ok, :async}`.

  ## Tracing Context

  The function sets up the tracing context and adds attributes related to the invocation.
  It uses OpenTelemetry to trace the client invoke with the kind set to `:client`.

  ## Retry Mechanism

  The function incorporates a retry mechanism with backoff, randomization, and timeout
  to handle potential errors during the invocation.

  ## Error Handling

  In case of errors during the invocation, appropriate logging and tracing events are added,
  and the error is re-raised with a stack trace.

  """
  def invoke_with_span(
        %InvocationRequest{
          actor: %Actor{id: %ActorId{name: _name, system: _actor_id_system} = actor_id} = actor,
          system: %ActorSystem{} = system,
          action_name: action_name,
          async: async?,
          metadata: metadata,
          caller: caller,
          pooled: pooled?
        } = request,
        opts
      ) do
  end

  defp get_proxy_info() do
    %ProxyInfo{
      protocol_major_version: 1,
      protocol_minor_version: 2,
      proxy_name: "spawn",
      proxy_version: "1.4.1"
    }
  end
end
