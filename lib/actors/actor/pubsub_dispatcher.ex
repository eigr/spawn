defmodule Actors.Actor.PubsubDispatcher do
  @moduledoc """
  Custom PubsubDispatcher dispatcher to send subscriber metadata with the message.
  """

  @doc false
  def dispatch(entries, :none, message) do
    for {pid, metadata} <- entries do
      send(pid, {message, metadata})
    end

    :ok
  end

  def dispatch(entries, from, message) do
    for {pid, metadata} <- entries, pid != from do
      send(pid, {message, metadata})
    end

    :ok
  end
end
