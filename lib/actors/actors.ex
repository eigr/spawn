defmodule Actors do
  @moduledoc """
  `Actors` It's the client API for the Spawn actors.
  Through this module we interact with the actors by creating,
  invoking or configuring them.
  """
  use Retry
  require Logger

  alias Actors.Actor.ActorSynchronousCallerProducer
  alias Actors.Config.Vapor, as: Config

  alias Eigr.Functions.Protocol.Actors.{
    ActorId,
    ActorSystem
  }

  alias Eigr.Functions.Protocol.{
    ActorInvocationResponse,
    InvocationRequest,
    RegistrationRequest,
    RegistrationResponse,
    SpawnRequest,
    SpawnResponse
  }

  alias Spawn.Utils.Nats

  @doc """
  Registers all actors defined in HostActor.

    * `registration` - The RegistrationRequest
    * `opts` - The options to create Actors
  ##
  """
  @spec register(RegistrationRequest.t(), any()) ::
          {:ok, RegistrationResponse.t()} | {:error, RegistrationResponse.t()}
  defdelegate register(registration, opts \\ []), to: ActorSynchronousCallerProducer

  @spec get_state(ActorId.t()) :: {:ok, term()} | {:error, term()}
  defdelegate get_state(id), to: ActorSynchronousCallerProducer

  @doc """
  Spawn actors defined in HostActor.

    * `registration` - The SpawnRequest
    * `opts` - The options to create Actors

  spawn_actor must be used when you want to create a concrete instance of an actor
  previously registered as unamed.
  That is, when an Actorid is associated with an actor of unamed type.
  This function only registers the metadata of the new actor, not activating it.
  This will occur when the sprite is first invoked.
  ##
  """
  @spec spawn_actor(SpawnRequest.t(), any()) :: {:ok, SpawnResponse.t()}
  defdelegate spawn_actor(spawn, opts \\ []), to: ActorSynchronousCallerProducer

  @doc """
  Makes a request to an actor.

    * `request` - The InvocationRequest
    * `opts` - The options to Invoke Actors
  ##
  """
  @spec invoke(InvocationRequest.t()) :: {:ok, :async} | {:ok, term()} | {:error, term()}
  def invoke(
        %InvocationRequest{
          system: %ActorSystem{name: system_name} = _system
        } = request,
        opts \\ []
      ) do
    case Config.get(Actors, :actor_system_name) do
      name when name === system_name ->
        ActorSynchronousCallerProducer.invoke(request, opts)

      _ ->
        invoke_with_nats(request, opts)
    end
  end

  @doc """
  Makes a request to an actor using Nats broker.

    * `request` - The InvocationRequest
    * `opts` - The options to Invoke Actors
  ##
  """
  @spec invoke(InvocationRequest.t()) :: {:ok, :async} | {:ok, term()} | {:error, term()}
  def invoke_with_nats(
        %InvocationRequest{
          actor: actor,
          system: %ActorSystem{name: system_name} = _system,
          async: async?
        } = request,
        opts \\ []
      ) do
    {_current, opts} =
      Keyword.get_and_update(opts, :span_ctx, fn span_ctx ->
        maybe_include_span(span_ctx)
      end)

    trace_context = :otel_propagator_text_map.inject_from(opts[:span_ctx], [])

    opts =
      Keyword.put(opts, :trace_context, trace_context)
      |> Keyword.merge(async: async?)

    case Nats.request(system_name, request, opts) do
      {:ok, %{body: {:error, error}}} ->
        {:error, error}

      {:ok, %{body: :async}} ->
        {:ok, :async}

      {:ok, %{body: body}} when is_binary(body) ->
        {:ok, ActorInvocationResponse.decode(body)}

      {:ok, %{body: _body}} ->
        {:error, :bad_response_type}

      {:error, :no_responders} ->
        Logger.error("Actor #{actor.id.name} not found on ActorSystem #{system_name}")
        {:error, :not_found}

      {:error, :timeout} ->
        Logger.error(
          "A timeout occurred while invoking the Actor #{actor.id.name} on ActorSystem #{system_name}"
        )

        {:error, :timeout}

      {:error, error} ->
        {:error, error}
    end
  end

  defp maybe_include_span(span_ctx) do
    if is_nil(span_ctx), do: {span_ctx, OpenTelemetry.Ctx.new()}, else: {span_ctx, span_ctx}
  end
end
