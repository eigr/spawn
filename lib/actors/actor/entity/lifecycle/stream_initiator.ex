defmodule Actors.Actor.Entity.Lifecycle.StreamInitiator do
  @moduledoc """
  Handles lifecycle functions for Actor Entity that interacts with Event Source mechanisms
  """
  require Logger

  alias Actors.Actor.Entity.Lifecycle.ProjectionConsumers

  alias Spawn.Actors.Actor
  alias Spawn.Actors.ProjectionSettings
  alias Spawn.Actors.ProjectionSubject

  alias Google.Protobuf.Timestamp

  alias Spawn.Utils.Nats
  alias Gnat.Jetstream.API.Stream, as: NatsStream
  alias Gnat.Jetstream.API.Consumer

  @consumer_not_found_code 10014
  @one_day_in_ms :timer.hours(24)
  @stream_not_found_code 10059

  @spec init_projection_stream(actor :: Actor.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def init_projection_stream(%Actor{} = actor) do
    name = stream_name(actor)

    with {:create_stream, :ok} <- {:create_stream, create_stream(actor, true)},
         {:create_consumer, :ok} <-
           {:create_consumer, create_consumer(actor, deliver_policy: :all)} do
      start_pipeline(actor)
    else
      {:create_stream, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [create_stream]. Details: #{inspect(error)}"
        )

        {:error, error}

      {:create_consumer, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [create_consumer]. Details: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  def init_sourceable_stream(%Actor{} = actor), do: create_stream(actor, false)

  def replay(stream_pid, actor, call_opts) do
    name = stream_name(actor)

    with {:stop_pipeline, :ok} <- {:stop_pipeline, stop_pipeline(stream_pid)},
         {:destroy_consumer, :ok} <- {:destroy_consumer, destroy_consumer(actor)},
         {:recreate_consumer, :ok} <- {:recreate_consumer, create_consumer(actor, call_opts)},
         {:start_pipeline, {:ok, newpid}} <- {:start_pipeline, start_pipeline(actor)} do
      {:ok, newpid}
    else
      {:stop_pipeline, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [stop_pipeline]. Details: #{inspect(error)}"
        )

        {:error, error}

      {:destroy_consumer, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [destroy_consumer]. Details: #{inspect(error)}"
        )

        {:error, error}

      {:recreate_consumer, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [recreate_consumer]. Details: #{inspect(error)}"
        )

        {:error, error}

      {:start_pipeline, error} ->
        Logger.error(
          "Error on start Projection #{name}. During phase [start_pipeline]. Details: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  defp build_consumer(stream_name, consumer_name, opts) do
    deliver_policy = Keyword.get(opts, :deliver_policy, :all)
    build_consumer_by_deliver(deliver_policy, stream_name, consumer_name, opts)
  end

  defp build_consumer_by_deliver(:by_start_time, stream_name, consumer_name, opts) do
    ten_minutes =
      DateTime.utc_now()
      |> DateTime.add(-@one_day_in_ms, :second)

    start_time = Keyword.get(opts, :opt_start_time, ten_minutes)

    %Consumer{
      stream_name: stream_name,
      durable_name: consumer_name,
      deliver_policy: :by_start_time,
      opt_start_time: start_time
    }
  end

  defp build_consumer_by_deliver(:all, stream_name, consumer_name, _opts) do
    %Consumer{stream_name: stream_name, durable_name: consumer_name, deliver_policy: :all}
  end

  defp build_sources(actor, %ProjectionSettings{} = settings) do
    settings.subjects
    |> Enum.map(fn %ProjectionSubject{} = subject ->
      opt_start_time =
        case subject.start_time do
          nil ->
            DateTime.from_unix!(0, :second)

          %Timestamp{seconds: start_at} ->
            DateTime.from_unix!(start_at, :second)
        end

      stream_name = stream_name(actor, subject.actor)

      %{
        name: stream_name,
        filter_subject: "actors.#{stream_name}.*.#{subject.action}",
        opt_start_time: opt_start_time
      }
    end)
  end

  defp build_stream_max_age(%ProjectionSettings{} = settings) do
    case Map.get(
           settings.events_retention_strategy || %{},
           :strategy,
           {:duration_ms, @one_day_in_ms}
         ) do
      {:infinite, true} -> 0
      # ms to ns
      {:duration_ms, max_age} -> max_age * 1_000_000
    end
  end

  defp conn, do: Nats.connection_name()

  defp create_stream(actor, true) do
    stream_name = stream_name(actor)
    max_age = build_stream_max_age(actor.settings.projection_settings)

    stream =
      %NatsStream{
        name: stream_name,
        subjects: [],
        sources: build_sources(actor, actor.settings.projection_settings),
        duplicate_window: max_age,
        max_age: max_age
      }

    case NatsStream.info(conn(), stream_name) do
      {:ok, _info} ->
        {:ok, _updated} = NatsStream.update(conn(), stream)

        :ok

      {:error, %{"code" => 404, "err_code" => @stream_not_found_code}} ->
        {:ok, %{created: _}} = NatsStream.create(conn(), stream)
        :ok

      error ->
        error
    end
  end

  defp create_stream(actor, false) do
    stream_name = stream_name(actor)
    max_age = build_stream_max_age(actor.settings.projection_settings)

    stream =
      %NatsStream{
        name: stream_name,
        subjects: ["actors.#{stream_name}.>"],
        max_age: max_age,
        duplicate_window: max_age
      }

    case NatsStream.info(conn(), stream_name) do
      {:ok, _info} ->
        :ok

      {:error, %{"code" => 404, "err_code" => @stream_not_found_code}} ->
        {:ok, %{created: _}} = NatsStream.create(conn(), stream)
        :ok

      error ->
        error
    end
  end

  defp create_consumer(actor, opts) do
    stream_name = stream_name(actor)
    consumer_name = stream_name(actor)

    case Consumer.info(conn(), stream_name, consumer_name) do
      {:ok, _info} ->
        :ok

      {:error,
       %{
         "code" => 404,
         "description" => "consumer not found",
         "err_code" => @consumer_not_found_code
       }} ->
        {:ok, %{created: _}} =
          Consumer.create(conn(), build_consumer(stream_name, consumer_name, opts))

        :ok

      error ->
        error
    end
  end

  defp destroy_consumer(actor) do
    stream_name = stream_name(actor)
    consumer_name = stream_name(actor)

    case Consumer.info(conn(), stream_name, consumer_name) do
      {:ok, _info} ->
        Consumer.delete(conn(), stream_name, consumer_name)

      {:error,
       %{
         "code" => 404,
         "description" => "consumer not found",
         "err_code" => @consumer_not_found_code
       }} ->
        :ok

      error ->
        error
    end
  end

  defp start_pipeline(actor) do
    ProjectionConsumers.new(%{
      actor_name: stream_name(actor),
      projection_pid: self(),
      strict_ordering: actor.settings.projection_settings.strict_events_ordering
    })
  end

  defp stop_pipeline(pid), do: Broadway.stop(pid)

  def stream_name(actor, actor_name \\ nil)
  def stream_name(%Actor{} = actor, actor_name), do: stream_name(actor.id, actor_name)

  def stream_name(actor_id, actor_name) do
    actor_name =
      actor_name ||
        if is_nil(actor_id.parent) or actor_id.parent == "",
          do: actor_id.name,
          else: actor_id.parent

    String.replace("#{actor_id.system}-#{actor_name}", ".", "-")
  end
end
