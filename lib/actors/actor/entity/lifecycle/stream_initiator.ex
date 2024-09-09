defmodule Actors.Actor.Entity.Lifecycle.StreamInitiator do
  @moduledoc """
  Handles lifecycle functions for Actor Entity that interacts with Event Source mechanisms
  """

  alias Actors.Actor.Entity.Lifecycle.StreamConsumer

  alias Eigr.Functions.Protocol.Actors.Actor
  alias Eigr.Functions.Protocol.Actors.ProjectionSettings
  alias Eigr.Functions.Protocol.Actors.ProjectionSubject

  alias Google.Protobuf.Timestamp

  alias Spawn.Utils.Nats
  alias Gnat.Jetstream.API.Stream, as: NatsStream
  alias Gnat.Jetstream.API.Consumer

  @stream_not_found_code 10059
  @consumer_not_found_code 10014
  @one_day_in_ms :timer.hours(24)

  def init_projection_actor(%Actor{} = actor) do
    :ok =
      create_stream(%NatsStream{
        name: actor.id.name,
        subjects: [],
        sources: build_sources(actor.settings.projection_settings),
        max_age: build_stream_max_age(actor.settings.projection_settings)
      })

    :ok =
      create_consumer(%Consumer{
        stream_name: actor.id.name,
        durable_name: actor.id.name,
        deliver_policy: :all
      })

    {:ok, _pid} =
      StreamConsumer.start_link(%{
        actor_name: actor.id.name,
        projection_pid: self(),
        strict_ordering: actor.settings.projection_settings.strict_events_ordering
      })

    :ok
  end

  def init_sourceable_actor(%Actor{} = actor) do
    :ok =
      create_stream(%NatsStream{
        name: actor.id.name,
        subjects: ["actors.#{actor.id.name}.>"],
        max_age: build_stream_max_age(actor.settings.projection_settings)
      })

    :ok
  end

  defp create_stream(%NatsStream{} = stream_opts) do
    case NatsStream.info(conn(), stream_opts.name) do
      {:ok, _info} ->
        :ok

      {:error, %{"code" => 404, "err_code" => @stream_not_found_code}} ->
        {:ok, %{created: _}} = NatsStream.create(conn(), stream_opts)
        :ok

      error ->
        error
    end
  end

  defp create_consumer(%Consumer{} = consumer_opts) do
    case Consumer.info(conn(), consumer_opts.stream_name, consumer_opts.durable_name) do
      {:ok, _info} ->
        :ok

      {:error, %{"code" => 404, "err_code" => @consumer_not_found_code}} ->
        {:ok, %{created: _}} = Consumer.create(conn(), consumer_opts)

        :ok

      error ->
        error
    end
  end

  defp conn, do: Nats.connection_name()

  defp build_sources(%ProjectionSettings{} = settings) do
    settings.subjects
    |> Enum.map(fn %ProjectionSubject{start_time: %Timestamp{seconds: start_at}} = subject ->
      %{
        name: subject.actor,
        filter_subject: "actors.#{subject.actor}.*.#{subject.action}",
        opt_start_time: start_at
      }
    end)
  end

  defp build_stream_max_age(%ProjectionSettings{} = settings) do
    case Map.get(settings.events_retention_strategy, :strategy, {:time_in_ms, @one_day_in_ms}) do
      {:infinite, true} -> 0
      {:time_in_ms, max_age} -> max_age * 1_000_000 # ms to ns
    end
  end
end
