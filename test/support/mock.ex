defmodule Actors.MockTest do
  @moduledoc false

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      alias Eigr.Functions.Protocol.ActorInvocationResponse

      setup do
        Agent.start_link(fn -> nil end, name: Actors.MockTest)
      end

      def mock_invoke_host_actor_with_ok_response(response) do
        Agent.put(Actors.MockTest, response)
      end
    end
  end
end
